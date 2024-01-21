#!/bin/bash
set -e
export DOCKER_BUILDKIT=0 
docker build --platform=linux/amd64 . -f Dockerfile.sample -t webview_sample
docker run -ti webview_sample bash -c 'xxd ~/projects/wxWidgets/samples/webview/webview.tar.bz2' | xxd -r > webview.tar.bz2
mkdir -p tmp
cd tmp
tar xvjf ../webview.tar.bz2
export GDK_BACKEND=x11
export WX_WEBVIEW_BACKEND=wxWebViewChromium
export LD_PRELOAD=`pwd`/3rdparty/cef/Release/libcef.so
./webview