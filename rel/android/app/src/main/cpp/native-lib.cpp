#include <jni.h>
#include <string>
#include <thread>
#include <unistd.h>
#include <dlfcn.h>

std::string jstring2string(JNIEnv *env, jstring jStr);
int start_logger();
static void logger_func();
static std::string log_file;
void (*startfun)(int argc, char **argv);

void ensure_slash(std::string& str)
{
    if (!str.empty() && str[str.size()-1] != '/') {
        str.append("/");
    }
}

void test_nif(std::string nif)
{
    void* lib = dlopen(nif.c_str(), RTLD_NOW);
    if (!lib) {
        printf("Failed opening %s: %s\n", nif.c_str(), dlerror());
        return;
    }

    void* sym = dlsym(lib, "nif_init");
    printf("%s: nif_init() => %lx\n", nif.c_str(), sym);

    // dlclose(lib);
}

#define ERROR(x) { printf(x); return x; }

const char* startErlang(std::string root_dir, std::string log_dir)
{
    ensure_slash(root_dir);
    ensure_slash(log_dir);
    log_file = log_dir + "elixir.log";

    std::string boot_file = root_dir + "releases/start_erl.data";
    FILE *fp = fopen(boot_file.c_str(), "rb");
    if (!fp) ERROR("Could not locate start_erl.data");

    char line_buffer[128];
    size_t read = fread(line_buffer, 1, sizeof(line_buffer) - 1, fp);
    fclose(fp);
    line_buffer[read] = 0;

    char* erts_version = strtok(line_buffer, " ");
    if (!erts_version) ERROR("Could not identify erts version in start_erl.data file");

    char* app_version = strtok(0, " ");
    if (!app_version) ERROR("Could not idenfity app version in start_erl.data file");


    std::string bin_dir = getenv("BINDIR");
    // keeping it static to keep the environment variable alive
    char *path = getenv("PATH");
    // keeping it static to keep the environment variable alive
    static std::string env_path = std::string("PATH=").append(path).append(":").append(bin_dir);

    chdir(root_dir.c_str());
    putenv((char *)env_path.c_str());

    start_logger();

    std::string liberlang = getenv("LIBERLANG");

    // RTLD_GLOBAL does not work on android
    // https://android-ndk.narkive.com/iNWj05IV/weak-symbol-linking-when-loading-dynamic-libraries
    // https://android.googlesource.com/platform/bionic/+/30b17e32f0b403a97cef7c4d1fcab471fa316340/linker/linker_namespaces.cpp#100
    void* lib = dlopen(liberlang.c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (!lib) ERROR("Failed opening liberlang.so\n")

    // std::string nif = root_dir + "lib/exqlite-0.5.1/priv/sqlite3_nif.so";
    // test_nif(nif);

    startfun = (void (*)(int, char**)) dlsym(lib, "erl_start");
    if (!startfun) ERROR("Failed loading erlang startfun\n")

    std::string config_path = root_dir + "releases/" + app_version + "/sys";
    std::string boot_path = root_dir + "releases/" + app_version + "/start";
    std::string lib_path = root_dir + "lib";
    std::string home_dir;
    if (const char* h = getenv("HOME")) {
        home_dir = h;
    } else {
        home_dir = root_dir + "home";
    }
    std::string update_dir;
    if (const char *u = getenv("UPDATE_DIR")) {
        update_dir = u;
    } else {
        update_dir = root_dir + "update";
    }

    const char *args[] = {
            "test_main",
            "-sbwt",
            "none",
            // Reduced literal super carrier to 10mb because of spurious error message on 9th gen iPads
            // "erts_mmap: Failed to create super carrier of size 1024 MB"
            "-MIscs",
            "10",
            "--",
            // "-init_debug",
            "-root",
            root_dir.c_str(),
            "-progname",
            "erl",
            "--",
            "-home",
            home_dir.c_str(), // Was without slash / at the end
            "--",
            "-kernel",
            "shell_history",
            "enabled",
            "--",
            // "-heart",
            "-pa",
            update_dir.c_str(),
            "-start_epmd",
            "false",
            //"-kernel",
            //"inet_dist_use_interface",
            //"{127,0,0,1}",
            "-elixir",
            "ansi_enabled",
            "true",
            "-noshell",
            "-s",
            "elixir",
            "start_cli",
            "-mode",
            "interactive",
            "-config",
            config_path.c_str(),
            "-boot",
            boot_path.c_str(),
            "-bindir",
            bin_dir.c_str(),
            "-boot_var",
            "RELEASE_LIB",
            lib_path.c_str(),
            "--",
            "--",
            "-extra",
            "--no-halt",
    };

    // std::thread erlang(run_erlang);
    // erlang.detach();
    startfun(sizeof(args) / sizeof(args[0]), (char **)args);
    return "ok";
}

extern "C" JNIEXPORT jstring JNICALL
Java_io_elixirdesktop_example_Bridge_startErlang(
        JNIEnv* env,
        jobject /* this */, jstring release_dir, jstring log_dir) {

    std::string home = jstring2string(env, release_dir);
    std::string logs = jstring2string(env, log_dir);
    return env->NewStringUTF(startErlang(home, logs));
}

std::string jstring2string(JNIEnv *env, jstring jStr) {
    if (!jStr)
        return "";

    const jclass stringClass = env->GetObjectClass(jStr);
    const jmethodID getBytes = env->GetMethodID(stringClass, "getBytes", "(Ljava/lang/String;)[B");
    const jbyteArray stringJbytes = (jbyteArray) env->CallObjectMethod(jStr, getBytes, env->NewStringUTF("UTF-8"));

    size_t length = (size_t) env->GetArrayLength(stringJbytes);
    jbyte* pBytes = env->GetByteArrayElements(stringJbytes, NULL);

    std::string ret = std::string((char *)pBytes, length);
    env->ReleaseByteArrayElements(stringJbytes, pBytes, JNI_ABORT);

    env->DeleteLocalRef(stringJbytes);
    env->DeleteLocalRef(stringClass);
    return ret;
}


#include <android/log.h>

static int pfd[2];
static const char *tag = "BEAM";

int start_logger()
{
    /* make stdout line-buffered and stderr unbuffered */
    setvbuf(stdout, 0, _IOLBF, 0);
    setvbuf(stderr, 0, _IONBF, 0);

    /* create the pipe and redirect stdout and stderr */
    pipe(pfd);
    dup2(pfd[1], 1);
    dup2(pfd[1], 2);

    std::thread logger(logger_func);
    logger.detach();
    return 0;
}

static void logger_func()
{
    static FILE* fp = 0;
    //if (!fp) fp = fopen("erlang.log", "wb");
    if (!fp) fp = fopen(log_file.c_str(), "wb");
    ssize_t rdsz;
    char buf[128];
    while((rdsz = read(pfd[0], buf, sizeof buf - 1)) > 0) {
        if (fp) {
            fwrite(buf, rdsz, 1, fp);
            fflush(fp);
        }
        if(buf[rdsz - 1] == '\n') --rdsz;
        buf[rdsz] = 0;  /* add null-terminator */
        __android_log_write(ANDROID_LOG_DEBUG, tag, buf);
    }
}
