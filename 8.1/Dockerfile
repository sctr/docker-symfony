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

ENV REQUIRED_PACKAGES="git make zlib-dev libzip-dev zip curl supervisor pcre linux-headers gettext-dev mysql-dev postgresql-dev rabbitmq-c icu libsodium-dev oniguruma-dev imagemagick libjpeg-turbo-dev freetype-dev libpng-dev libwebp libwebp-dev libpng freetype libjpeg-turbo libmaxminddb"
ENV DEVELOPMENT_PACKAGES="autoconf g++ openssh-client tar python3 py-pip pcre-dev rabbitmq-c-dev icu-dev imagemagick-dev libmaxminddb-dev"
ENV PECL_PACKAGES="redis apcu ast mongodb maxminddb"
ENV EXT_PACKAGES="pdo_mysql pdo_pgsql bcmath opcache mbstring iconv gettext intl exif sodium gd sysvmsg sysvsem sysvshm pcntl"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_CACHE_DIR /tmp

WORKDIR /app

# Copying manifest files to host
COPY ./8.1/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install Packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES $DEVELOPMENT_PACKAGES

# Fix Iconv
RUN apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install Zip extension
RUN docker-php-ext-configure zip && docker-php-ext-install zip && docker-php-ext-enable zip

# Install Non-Pecl Packages
RUN docker-php-ext-install $EXT_PACKAGES && docker-php-ext-enable $EXT_PACKAGES

# Configure GD to use freetype fonts
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp --with-avif && docker-php-ext-install gd && docker-php-ext-enable gd

# Install sockets
RUN CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install sockets && docker-php-ext-enable sockets

# Install Pecl Packages
RUN yes '' | pecl install -f $PECL_PACKAGES; \
    docker-php-ext-enable $PECL_PACKAGES

# AMQP from master @TODO upgrade to release version when php8 support is ready
ENV EXT_AMQP_VERSION=master
RUN docker-php-source extract \
    && apk -Uu add git rabbitmq-c-dev \
    && git clone --branch $EXT_AMQP_VERSION --depth 1 https://github.com/php-amqp/php-amqp.git /usr/src/php/ext/amqp \
    && cd /usr/src/php/ext/amqp && git submodule update --init \
    && docker-php-ext-install amqp \
    && docker-php-ext-enable amqp \
    && docker-php-source delete

# Imagick from master @TODO upgrade to release version when php8 support is ready
ENV EXT_IMAGICK_VERSION=master
RUN docker-php-source extract \
    && git clone --branch $EXT_IMAGICK_VERSION --depth 1 https://github.com/Imagick/imagick.git /usr/src/php/ext/imagick \
    && cd /usr/src/php/ext/imagick && git submodule update --init \
    && docker-php-ext-install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-source delete \

# Delete Non-Required Packages
RUN apk del $DEVELOPMENT_PACKAGES
