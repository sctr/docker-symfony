ARG PHP_VERSION=8.4.0RC4-fpm-alpine
ARG CADDY_VERSION=2

# -----------------------------------------------------
# Caddy Install
# -----------------------------------------------------
FROM caddy:$CADDY_VERSION-builder-alpine AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR

ENV REQUIRED_PACKAGES="git make unzip curl supervisor linux-headers gettext acl fcgi pcre python3 gcc libxslt gnupg imagemagick imagemagick-pdf libavif libwebp libpng freetype libjpeg-turbo rabbitmq-c ca-certificates coreutils"
ENV EXTENSIONS="redis apcu ast zip mongodb maxminddb amqp pdo_mysql pdo_pgsql bcmath opcache gettext intl exif sysvmsg sysvsem sysvshm pcntl gmp xsl bz2 gd igbinary uuid sockets Imagick/imagick@65e27f2bc0"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

# Copying manifest files to host
COPY ./8.4/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# PHP extensions installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install required packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES

# Install PHP extensions
RUN IPE_ICU_EN_ONLY=1 install-php-extensions $EXTENSIONS

# Update ulimit
RUN ulimit -n 16384
