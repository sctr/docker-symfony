ARG PHP_VERSION=8.5
ARG CADDY_VERSION=2

# -----------------------------------------------------
# Caddy Install
# -----------------------------------------------------
FROM caddy:$CADDY_VERSION-builder AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build \
    --with github.com/ueffel/caddy-brotli \
    --with github.com/ggicci/caddy-jwt@28e0de3db362a787564352ec22e97aa743a371f3 #1.2.0

# -----------------------------------------------------
# Build xberg PHP extension from Rust source
# (successor to kreuzberg)
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm AS xberg-builder

# Install build dependencies (tesseract is vendored/statically built by xberg)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        g++ \
        pkg-config \
        libssl-dev \
        libmagic-dev \
        libuv1-dev \
        libde265-dev \
        libaom-dev \
        libx265-dev \
        libdav1d-dev \
        libnuma-dev \
        clang \
        curl \
        file \
        git \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# xberg's heic feature links system libheif >= 1.21; trixie ships 1.19
ARG LIBHEIF_VERSION=1.23.0
RUN curl -fsSL "https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz" | tar xz -C /tmp \
    && cmake -S /tmp/libheif-${LIBHEIF_VERSION} -B /tmp/libheif-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DWITH_EXAMPLES=OFF \
        -DWITH_GDK_PIXBUF=OFF \
        -DBUILD_TESTING=OFF \
    && cmake --build /tmp/libheif-build -j"$(nproc)" \
    && cmake --install /tmp/libheif-build \
    && rm -rf /tmp/libheif-*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ARG XBERG_VERSION=v1.0.0-rc.28
RUN git clone --depth 1 --recurse-submodules --shallow-submodules --branch ${XBERG_VERSION} https://github.com/xberg-io/xberg.git /tmp/xberg \
    && cd /tmp/xberg/crates/xberg-php \
    && for i in 1 2 3 4 5; do \
         cargo build --release && break || { \
           echo "cargo build failed (attempt $i), retrying in $((i*30))s..."; \
           sleep $((i*30)); \
         }; \
       done \
    && test -f /tmp/xberg/target/release/libxberg_php.so

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf opentelemetry"

ENV BUILD_DEPS="make git autoconf wget"

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

WORKDIR /app

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
        acl \
        ca-certificates \
        curl \
        file \
        gettext \
        procps \
        supervisor \
        unzip \
        zip \
        imagemagick \
        webp \
        gifsicle \
        jpegoptim \
        optipng \
        pngquant \
        # libheif codec runtimes for ext-xberg
        libde265-0 \
        libaom3 \
        libx265-215 \
        libdav1d7 \
        libnuma1 \
	&& rm -rf /var/lib/apt/lists/*


# Xberg PHP extension (built from Rust source), successor to kreuzberg
COPY --from=xberg-builder /tmp/xberg/target/release/libxberg_php.so /tmp/xberg.so
RUN mv /tmp/xberg.so $(php -r "echo ini_get('extension_dir');")/xberg.so \
    && echo "#extension=xberg" > $PHP_INI_DIR/conf.d/xberg.ini

# libheif >= 1.21 runtime for ext-xberg (apt ships older); resolved via LD_LIBRARY_PATH=/usr/local/lib
COPY --from=xberg-builder /usr/local/lib/libheif.so.1* /usr/local/lib/

# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
ARG VIPS_VERSION=8.18.2
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Copying manifest files to host
COPY ./8.5/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml

# Update ulimit
RUN ulimit -n 16384
