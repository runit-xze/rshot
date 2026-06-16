FROM debian:bookworm-slim

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
    imagemagick \
    xdg-utils \
    libimage-magick-perl \
    liblocale-gettext-perl \
    && rm -rf /var/lib/apt/lists/*

# Install Carton for dependency management
RUN cpanm Carton

WORKDIR /app

# Copy dependency files
COPY cpanfile .

# Install Perl dependencies
RUN carton install

# Copy the rest of the application
COPY . .

# Run tests by default
CMD ["carton", "exec", "make", "test"]
