# TodoApp Android: An Android Sample App

This Android Studio project wraps the [Desktop Sample App](https://github.com/elixir-desktop/desktop-example-app) (the parent repository) so it can run on an Android phone. The Elixir LiveView project lives at the repository root (`../..`); this folder is the Android Studio project that embeds it.

## Runtime Notes

The pre-built Erlang runtime for Android ARM/ARM64/x86_64 is committed in `app/src/main/assets/*-runtime.zip` (and the matching `*-nif-exqlite.zip` files). These native runtime files include Erlang/OTP and the exqlite NIF and are produced by the CI of the [Desktop Runtime](https://github.com/elixir-desktop/runtimes) repository.

> **Git LFS required.** All `*.zip` and `*.jar` files in this folder (the runtime/NIF blobs, `app/libs/erlang.jar`, and the gradle wrapper jar) are tracked through [Git LFS](https://git-lfs.com/). Install it once (`apt install git-lfs` / `brew install git-lfs`) and then run `git lfs install` in your clone — otherwise these files will appear as ~130 byte text pointers and the APK build will fail.

Because Erlang/OTP has many native hooks for networking and cryptography, the Erlang version used to compile the BEAM bytecode embedded in the APK MUST match the bundled runtime. In this sample that is **Erlang/OTP 26.2.5** with **Elixir 1.17.2-otp-26**. The version requirement is encoded in `app/.tool-versions`; `app/run_mix` reads it and exports the matching `ASDF_*_VERSION` environment variables before invoking `mix release`, so the parent repository's own `.tool-versions` (used for desktop builds with a newer OTP) is not picked up by accident.

## Building from the command line

The repository ships a `scripts/build_android.sh` wrapper that produces an APK end-to-end. Run it from the repository root:

```shell
./scripts/build_android.sh                  # debug APK
./scripts/build_android.sh assembleRelease  # release APK
./scripts/build_android.sh bundleRelease    # AAB for the Play Store
```

The script delegates to `./gradlew` inside `rel/android/`. Gradle's `buildNum` task in turn runs `app/run_mix`, which builds the Elixir release for `MIX_TARGET=android` from the parent project and zips it into `app/src/main/assets/app.zip`. The same script is what GitHub Actions uses (see `.github/workflows/android.yml`), so local and CI builds stay in sync.

The resulting APK lands in:

```
rel/android/app/build/outputs/apk/debug/app-debug.apk
```

### Required tooling

1. [Android Studio](https://developer.android.com/studio) with the NDK and CMake 3.22.x components installed.
2. JDK 17 (Android Studio bundles a JBR you can reuse).
3. Node.js (used by the Phoenix asset pipeline).
4. Erlang/OTP 26.2.5 + Elixir 1.17.2-otp-26. The simplest way is via [asdf](https://asdf-vm.com/):

    ```shell
    asdf plugin add erlang
    asdf plugin add elixir
    asdf plugin add nodejs
    cd rel/android/app && asdf install
    ```

## Opening the project in Android Studio

Use **File → Open…** and select the `rel/android/` folder. Android Studio will recognise `settings.gradle`, `build.gradle` and the `app/` module and import the project. From there you can run/debug the `app` configuration normally; the buildNum task will invoke `run_mix` automatically before each build, producing `app.zip` from the live source tree at the repository root.

## Customize app name and branding

Update these places with your package name:

1) App name in [strings.xml](app/src/main/res/values/strings.xml#L2) and [settings.gradle](settings.gradle)
1) Package names in [Bridge.kt:1](app/src/main/java/io/elixirdesktop/example/Bridge.kt#L1) and [MainActivity.kt:1](app/src/main/java/io/elixirdesktop/example/MainActivity.kt#L1) (rename `package io.elixirdesktop.example` -> `com.yourapp.name` or use the Android Studios refactor tool)
1) App icon: [ic_launcher_foreground.xml](app/src/main/res/drawable-v24/ic_launcher_foreground.xml) and [ic_launcher-playstore.png](app/src/main/ic_launcher-playstore.png)
1) App colors: [colors.xml](app/src/main/res/values/colors.xml) and launcher background [ic_launcher_background.xml](app/src/main/res/values/ic_launcher_background.xml)

## Known todos

### Initial Startup could be faster

Running the app for the first time will extract the full Elixir & App runtime at start. On my Phone this takes around 10 seconds. After that a cold app startup takes ~3-4 seconds.

### Menus and other integration not yet available

This sample only launch the elixir app and shows it in an Android WebView. There is no integration yet with the Android Clipboard, sharing or other OS capabilities. They can though easily be added to the `Bridge.kt` file when needed.

## Other notes

- Android specific settings, icons and metadata are all contained in this Android Studio wrapper project.

- `Bridge.kt` and the native library are doing most of the wrapping of the Elixir runtime.

## Screenshots

![Icons](/icon.jpg?raw=true "App in Icon View")
![App](/app.png?raw=true "Running App")

## Architecture

![App](/android_elixir.png?raw=true "Architecture")

The Android App is initializing the Erlang VM and starting it up with a new environment variable `BRIDGE_PORT`. This environment variable is used by the `Bridge` project to connect to a local TCP server _inside the android app_. Through this new TCP communication channel all calls that usually would go to `wxWidgets` are now redirected. The Android side of things implements handling in `Bridge.kt`.  
