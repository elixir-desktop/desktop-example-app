#include <jni.h>
#include <string>
#include <thread>
#include <unistd.h>
#include <dlfcn.h>
#include <android/log.h>

std::string jstring2string(JNIEnv *env, jstring jStr);
int start_logger();
static void logger_func();
static std::string log_file;

extern "C" {
extern void erl_start(int argc, char **argv);
}

void ensure_slash(std::string& str)
{
    if (!str.empty() && str[str.size()-1] != '/') {
        str.append("/");
    }
}

bool write_inetrc(std::string& root_dir)
{
    std::string inetrc = root_dir + "inetrc";
    static std::string env = "ERL_INETRC=" + inetrc;
    putenv((char *)env.c_str());

    FILE *fp = fopen(inetrc.c_str(), "w");
    if (!fp) return false;
    fprintf(fp, "%% enable EDNS, 0 means enable YES!\n");
    fprintf(fp, "{edns,0}.\n");
    fprintf(fp, "{alt_nameserver, {8,8,8,8}}.\n");
    fprintf(fp, "%% specify lookup method\n");
    fprintf(fp, "{lookup, [dns]}.\n");
    fclose(fp);
    return true;
}

#define ERROR(x) { printf(x); return x; }
const char* startErlang(std::string root_dir, std::string log_dir)
{
    // Startup timing: measure BEAM VM initialization
    __android_log_print(ANDROID_LOG_INFO, "STARTUP_NATIVE", "startErlang begin");

    ensure_slash(root_dir);
    ensure_slash(log_dir);
    log_file = log_dir + "elixir.log";

    if (!write_inetrc(root_dir)) {
        ERROR("Could not write inetrc");
    }

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

    std::string config_path = root_dir + "releases/" + app_version + "/sys";
    std::string boot_path = root_dir + "releases/" + app_version + "/start";
    std::string lib_path = root_dir + "lib";
    std::string home_dir;
    std::string update_dir;

    if (const char* h = getenv("HOME")) {
        home_dir = h;
    } else {
        home_dir = root_dir + "home";
    }
    
    if (const char *u = getenv("UPDATE_DIR")) {
        update_dir = u;
    } else {
        update_dir = root_dir + "update";
    }
    ensure_slash(update_dir);

    const char *args[] = {
            "test_main",
            "-sssdio",
            "128",
            "-sbwt",
            "none",
            // Reduced literal super carrier to 40mb because of spurious error message on 9th gen iPads
            // "erts_mmap: Failed to create super carrier of size 1024 MB"
            "-MIscs",
            "40",
            "--",
            // "-init_debug",
            "-bindir",
            bin_dir.c_str(),
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
            "-boot_var",
            "RELEASE_LIB",
            lib_path.c_str(),
            "--",
            "-pa",
            update_dir.c_str(),
            "-shutdown_time",
            "0",
            "--",
            "--",
            //"-code_path_choice",
            //"strict",
            "-extra",
            "--no-halt",
    };

    __android_log_print(ANDROID_LOG_INFO, "STARTUP_NATIVE", "calling erl_start");
    erl_start(sizeof(args) / sizeof(args[0]), (char **)args);
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
