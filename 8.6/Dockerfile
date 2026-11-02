ARG PHP_VERSION=8.6.0RC4
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
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm-trixie

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

# PHP 8.6 removed internal C APIs (XtOffsetOf, zval_dtor, INI_STR/INT/FLT, ...). Until PECL releases
# support 8.6: apcu (5.1.29 release commit, not on PECL), igbinary and imagick are built from pinned
# upstream commits, amqp from the sctr/php-amqp fork (php-8.6-support branch, pending upstream),
# redis by scripts/install-phpredis.sh, and protobuf and grpc are left out because no upstream code
# compiles on 8.6 yet.
ENV EXTENSIONS="sctr/php-amqp@7a4318b41915d8957ab207de43783d94db25aa25 krakjoe/apcu@66300e28647c16fef7672a5add532f4262b23a75 ast bcmath exif ffi gd gettext gmp igbinary/igbinary@2b1f5d62e3037b07c2a46499ac32091cdb41fb40 Imagick/imagick@55ed2e9fda264395636a2e27e51f31673f5566ab intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql sockets sysvmsg sysvsem sysvshm uuid xsl zip opentelemetry zstd symfony/php-ext-deepclone@v0.8.9"

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

# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
ARG VIPS_VERSION=8.18.7
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

ARG PHPREDIS_REF=671e726e7d87916ffc1c8c8dbbb20c355bcd731a
COPY --chmod=755 scripts/install-phpredis.sh /tmp/install-phpredis.sh
RUN /tmp/install-phpredis.sh ${PHPREDIS_REF} && rm /tmp/install-phpredis.sh

# Keep frequently changing binaries after dependency installation.
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# Copying manifest files to host
COPY ./8.6/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
