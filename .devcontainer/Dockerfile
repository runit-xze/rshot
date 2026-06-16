FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    cpanminus \
    build-essential \
    libgtk-3-dev \
    libgoocanvas-2.0-dev \
    libwnck-3-dev \
    libglib2.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libxml2-dev \
    libdbus-1-dev \
    libssl-dev \
    gir1.2-gtk-3.0 \
    gir1.2-goocanvas-2.0 \
    gir1.2-wnck-3.0 \
    gir1.2-pango-1.0 \
    gir1.2-gdkpixbuf-2.0 \
    gir1.2-glib-2.0 \
    imagemagick \
    xdg-utils \
    libimage-magick-perl \
    liblocale-gettext-perl \
    libperl-critic-perl \
    libperl-tidy-perl \
    sudo \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Carton and LSP support tools
RUN cpanm --notest Carton App::PerlNavigator

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /app
