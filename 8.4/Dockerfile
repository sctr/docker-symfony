ARG PHP_VERSION=8.4.0RC4-fpm-alpine
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

ENV REQUIRED_PACKAGES="git make zip curl supervisor linux-headers gettext acl fcgi pcre python3 libpq gcc libxslt imagemagick imagemagick-pdf libavif libwebp libpng freetype libjpeg-turbo rabbitmq-c"
ENV EXTENSIONS="redis apcu ast zip mongodb maxminddb amqp pdo_mysql pdo_pgsql bcmath opcache gettext intl exif sysvmsg sysvsem sysvshm pcntl gmp xsl imagick/imagick@master bz2 gd igbinary uuid"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

# Copying manifest files to host
COPY ./8.4/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES

# Install PHP extensions
RUN install-php-extensions $EXTENSIONS

# Install sockets
RUN CFLAGS="$CFLAGS -D_GNU_SOURCE" docker-php-ext-install sockets && docker-php-ext-enable sockets

# Update ulimit
RUN ulimit -n 16384
