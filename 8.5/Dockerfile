ARG PHP_VERSION=8.5.13
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
# libvips (built apart from PHP so it caches and compiles in parallel)
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
# -----------------------------------------------------
FROM debian:trixie-slim AS libvips
ARG VIPS_VERSION=8.18.7
COPY --chmod=755 scripts/build-libvips.sh /tmp/build-libvips.sh
RUN /tmp/build-libvips.sh ${VIPS_VERSION}

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm-trixie

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip protobuf opentelemetry zstd-0.18.0 symfony/php-ext-deepclone@v0.8.9"

WORKDIR /app

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
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

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# libvips from its own stage, plus the Debian packages it needs at runtime
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --link --from=libvips /usr/local/ /usr/local/
COPY --from=libvips /vips-runtime-packages /tmp/vips-runtime-packages
RUN apt-get update \
	&& xargs -a /tmp/vips-runtime-packages apt-get install -y --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* /tmp/vips-runtime-packages \
	&& ldconfig

# Keep frequently changing binaries after dependency installation.
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# Copying manifest files to host
COPY ./8.5/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
