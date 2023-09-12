FROM ubuntu:20.04
ENV WXWIDGETS_VERSION=3.1.4
ENV OTP_VERSION=25.0.4
ENV ELIXIR_VERSION=1.13.4
ENV DEBIAN_FRONTEND=noninteractive

# Installing wxWidgets
RUN apt-get update
RUN apt-get install -y libssl-dev libjpeg-dev libpng-dev libtiff-dev zlib1g-dev libncurses5-dev libssh-dev unixodbc-dev libgmp3-dev libwebkit2gtk-4.0-dev libsctp-dev libgtk-3-dev libnotify-dev libsecret-1-dev catch mesa-common-dev libglu1-mesa-dev freeglut3-dev
RUN apt-get install -y git

RUN mkdir ~/projects && cd ~/projects && \
    git clone https://github.com/wxWidgets/wxWidgets.git

RUN apt-get install -y g++
RUN cd ~/projects/wxWidgets && \   
    git checkout v${WXWIDGETS_VERSION} --recurse-submodules && \
    git submodule update --init
    
RUN apt-get install -y make
RUN cd ~/projects/wxWidgets && \
    ./configure --prefix=/usr/local/wxWidgets --enable-clipboard --enable-controls \
            --enable-dataviewctrl --enable-display \
            --enable-dnd --enable-graphics_ctx \
            --enable-std_string --enable-svg \
            --enable-unicode --enable-webview \
            --with-expat --with-libjpeg \
            --with-libpng --with-libtiff \
            --with-opengl --with-zlib \
            --disable-precomp-headers --disable-monolithic && \
    make -j2 && \
    make install

# Installing Erlang
RUN apt-get install -y curl
ENV ASDF_DIR=/root/.asdf
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} && \
    . ${ASDF_DIR}/asdf.sh && \
    asdf plugin add erlang && \
    asdf plugin add elixir && \
    echo "erlang ${OTP_VERSION}" >> .tool-versions && \
    echo "elixir ${ELIXIR_VERSION}-otp-25" >> .tool-versions && \
    export KERL_CONFIGURE_OPTIONS="--with-wxdir=/usr/local/wxWidgets" && \
    asdf install

# Compile and lint
COPY mix.exs mix.lock .formatter.exs ./
RUN . ${ASDF_DIR}/asdf.sh && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix lint

# Build Release
RUN . ${ASDF_DIR}/asdf.sh && \
    mix desktop.installer

