ARG PHP_VERSION=8.4
ARG CADDY_VERSION=2

# -----------------------------------------------------
# Caddy Install
# -----------------------------------------------------
FROM caddy:$CADDY_VERSION-builder AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR

ENV EXTENSIONS="redis apcu ast zip mongodb maxminddb amqp pdo_mysql pdo_pgsql bcmath opcache gettext intl exif sysvmsg sysvsem sysvshm pcntl gmp xsl bz2 gd igbinary uuid sockets imagick"

ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

WORKDIR /app

# Copying manifest files to host
COPY ./8.4/manifest /

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        acl \
        file \
        gettext \
        gifsicle \
        git \
        imagemagick \
        jpegoptim \
        libexif-dev \
        libheif-dev \
        libvips42 \
        optipng \
        pngquant \
        procps \
        supervisor \
        unzip \
        webp \
        zip \
	&& rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Update ulimit
RUN ulimit -n 16384
