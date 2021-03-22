# TodoApp: A Desktop Sample App

This application is an example of an Elixir live view based desktop application. It uses the library Desktop to create a native & modern look and feel.

## General notes

To run this app you need a most recent Erlang Release Candidat 24rc1! and at least Elixir 1.10.4.
At the time of writing the required :wxWebView component has just been pulled into Erlang OTP 24 RC1  https://www.erlang.org/news/144

For best experience use a wxWidgets version >= 3.1.x e.g. specifiy your own built version:
`KERL_CONFIGURE_OPTIONS="--with-wxdir=/path/to/your/wxWidgets" kerl build git https://github.com/erlang/otp.git OTP-24.0-rc1 24.rc1`

For windows platform build instructions check-out the Erlang documentation: https://erlang.org/doc/installation_guide/INSTALL-WIN32.html

## Screenshots

![Linux build](/nodeploy/linux_todo.png?raw=true "Linux build")
![Windows build](/nodeploy/windows_todo.png?raw=true "Windows build")
![MacOS build](/nodeploy/macos_todo.png?raw=true "MacOS build")
