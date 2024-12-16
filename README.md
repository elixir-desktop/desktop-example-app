# TodoApp: A Desktop Sample App

This application is an example of an Elixir LiveView based desktop application. It uses the elixir-desktop library and a local SQLite database to create a web-technology based desktop app.

## Dependencies

This example assumes you've got installed:

- git
- Elixir, at least 1.14
- Erlang, at least OTP 24
- wxWidgets
- npm
- C compiler (make/nmake) for SQLite

If you want to build for iOS you'll also need xcode and in order to build for Android you'll need the
Android Studio.

## Application set-up

Run:

```bash
cd assets
npm install
cd ..
mix deps.get
mix assets.deploy
```

To build binaries locally run:

```bash
mix desktop.installer
```

## Screenshots

![Linux build](/nodeploy/linux_todo.png?raw=true "Linux build")
![Windows build](/nodeploy/windows_todo.png?raw=true "Windows build")
![MacOS build](/nodeploy/macos_todo.png?raw=true "MacOS build")
![Android build](/nodeploy/android_todo.png?raw=true "Android build")
![iOS build](/nodeploy/ios_todo.png?raw=true "iOS build")
