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
    --with github.com/ueffel/caddy-brotli

# -----------------------------------------------------
# Build kreuzberg PHP extension from Rust source
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm AS kreuzberg-builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        g++ \
        pkg-config \
        libssl-dev \
        libleptonica-dev \
        libtesseract-dev \
        clang \
        curl \
        file \
        git \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ARG KREUZBERG_VERSION=v4.9.4
RUN git clone --depth 1 --branch ${KREUZBERG_VERSION} https://github.com/kreuzberg-dev/kreuzberg.git /tmp/kreuzberg \
    && cd /tmp/kreuzberg/crates/kreuzberg-php \
    && for i in 1 2 3 4 5; do \
         cargo build --release && break || { \
           echo "cargo build failed (attempt $i), retrying in $((i*30))s..."; \
           sleep $((i*30)); \
         }; \
       done \
    && test -f /tmp/kreuzberg/target/release/libkreuzberg_php.so

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
	&& rm -rf /var/lib/apt/lists/*


# Kreuzberg PHP extension (built from Rust source)
COPY --from=kreuzberg-builder /tmp/kreuzberg/target/release/libkreuzberg_php.so /tmp/kreuzberg.so
RUN mv /tmp/kreuzberg.so $(php -r "echo ini_get('extension_dir');")/kreuzberg.so \
    && echo "#extension=kreuzberg" > $PHP_INI_DIR/conf.d/kreuzberg.ini

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
