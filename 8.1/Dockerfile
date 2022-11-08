ARG PHP_VERSION=8.1
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

ENV REQUIRED_PACKAGES="git make zip libzip-dev curl supervisor pcre imagemagick libavif libwebp libpng freetype libjpeg-turbo libmaxminddb rabbitmq-c gmp"
ENV DEVELOPMENT_PACKAGES="autoconf g++ openssh-client tar linux-headers python3 py-pip postgresql-dev pcre-dev zlib-dev rabbitmq-c-dev icu-dev icu-data-full imagemagick-dev libmaxminddb-dev libsodium-dev oniguruma-dev libavif-dev libjpeg-turbo-dev freetype-dev libpng-dev libwebp-dev gettext-dev mysql-dev postgresql-dev gmp-dev libxslt-dev"
ENV PECL_PACKAGES="redis apcu ast mongodb maxminddb"
ENV EXT_PACKAGES="pdo_mysql pdo_pgsql bcmath opcache gettext intl exif sodium gd sysvmsg sysvsem sysvshm pcntl gmp xsl"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

# Copying manifest files to host
COPY ./8.1/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install required packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES

# Install development packages
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS $DEVELOPMENT_PACKAGES

# Install Zip extension
RUN docker-php-ext-configure zip && docker-php-ext-install zip && docker-php-ext-enable zip

# Fix Iconv
RUN apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install Non-Pecl Packages
RUN docker-php-ext-install -j$(nproc) $EXT_PACKAGES && docker-php-ext-enable $EXT_PACKAGES

# Configure GD to use freetype fonts
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp --with-avif && docker-php-ext-install -j$(nproc) gd && docker-php-ext-enable gd

# Install sockets
RUN CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install sockets && docker-php-ext-enable sockets

# Install Pecl Packages
RUN yes '' | pecl install -f $PECL_PACKAGES; \
    pecl clear-cache; \
    docker-php-ext-enable $PECL_PACKAGES

# AMQP from master @TODO upgrade to release version when php8 support is ready
ENV EXT_AMQP_VERSION=master
RUN docker-php-source extract \
    && git clone --branch $EXT_AMQP_VERSION --depth 1 https://github.com/php-amqp/php-amqp.git /usr/src/php/ext/amqp \
    && cd /usr/src/php/ext/amqp && git submodule update --init \
    && docker-php-ext-install -j$(nproc) amqp \
    && docker-php-ext-enable amqp \
    && docker-php-source delete

# Imagick from master @TODO upgrade to release version when php8 support is ready
ENV EXT_IMAGICK_VERSION=master
RUN docker-php-source extract \
    && git clone --branch $EXT_IMAGICK_VERSION --depth 1 https://github.com/Imagick/imagick.git /usr/src/php/ext/imagick \
    && cd /usr/src/php/ext/imagick && git submodule update --init \
    && docker-php-ext-install -j$(nproc) imagick \
    && docker-php-ext-enable imagick \
    && docker-php-source delete \

# PHP run deps cleanup
RUN runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .app-phpexts-rundeps $runDeps; \
    apk del .build-deps
