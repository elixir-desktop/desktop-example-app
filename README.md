# Todos Sample App

This application is an example of an Elixir live view based desktop application. It uses :wxWebView, :wxNotification and :wxTaskbarIcon to create a native & modern look and feel.

## General notes

To run this app you need a most recent Erlang build and at least Elixir 1.10.4.
At the time of writing the required :wxWebView component is not yet pulled into Erlang OTP master https://github.com/erlang/otp/pull/3027

You can still preview with :wxWebView support by build the pull requested branch. E.g. using kerl:
`kerl build git https://github.com/diodechain/otp.git letz/wxWebView 24.webview`

For best experience use a wxWidgets version >= 3.1.x e.g. specifiy your own built version:
`KERL_CONFIGURE_OPTIONS="--with-wxdir=/path/to/your/wxWidgets" kerl build git https://github.com/diodechain/otp.git letz/wxWebView 24.webview`

For windows platform build instructions check-out the Erlang documentation: https://erlang.org/doc/installation_guide/INSTALL-WIN32.html
