ARG PHP_VERSION=8.3
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
FROM php:$PHP_VERSION-fpm-alpine

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR

ENV REQUIRED_PACKAGES="git make unzip curl supervisor linux-headers gettext acl fcgi pcre python3 gcc libxslt gnupg imagemagick imagemagick-pdf libavif libwebp libpng freetype libjpeg-turbo rabbitmq-c ca-certificates coreutils"
ENV EXTENSIONS="redis apcu ast zip mongodb maxminddb amqp pdo_mysql pdo_pgsql bcmath opcache gettext intl exif sysvmsg sysvsem sysvshm pcntl gmp xsl Imagick/imagick@65e27f2bc0 bz2 gd igbinary uuid sockets"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

# Copying manifest files to host
COPY ./8.3/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# PHP extensions installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install required packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN install-php-extensions $EXTENSIONS

# Update ulimit
RUN ulimit -n 16384
