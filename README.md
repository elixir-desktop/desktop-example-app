# TodoApp: A Desktop Sample App

This application is an example of an Elixir LiveView based desktop application. It uses the elixir-desktop library and a local SQLite database to create a web-technology based desktop app.

## Changes in 1.2

- Added `desktop_deployment` and CI to generate windows+macos+linux binaries

To build binaries locally run:

```bash
mix desktop.installer
```

## Changes in 1.1

- Updated to Phoenix 1.7 and LiveView 0.18

## Changes in 1.0

- Updated to Phoenix 1.6 with esbuild+dart_scss
- Added iOS platform example wrapper (see https://github.com/elixir-desktop/ios-example-app)
- Added Android platform example wrapper (see https://github.com/elixir-desktop/android-example-app)

## General notes

To run this app you need at least Erlang 24 and recent builds of wxWidgets and at least
Elixir 1.11.4.

## Dependencies

This example assumes you've got installed:

- git
- Elixir, at least 1.11.4
- Erlang, at least OTP 24
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
mix assets.deploy
```

## Screenshots

![Linux build](/nodeploy/linux_todo.png?raw=true "Linux build")
![Windows build](/nodeploy/windows_todo.png?raw=true "Windows build")
![MacOS build](/nodeploy/macos_todo.png?raw=true "MacOS build")
![Android build](/nodeploy/android_todo.png?raw=true "Android build")
![iOS build](/nodeploy/ios_todo.png?raw=true "iOS build")
