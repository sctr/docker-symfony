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

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/pberkel/caddy-storage-redis \
    --with github.com/ggicci/caddy-jwt

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

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf"

ENV BUILD_DEPS="make git autoconf wget"

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
RUN apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
        acl \
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
ARG VIPS_VERSION=8.18.0
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Copy Imagemagick policy
COPY /8.4/manifest/IM7-policy.xml /etc/ImageMagick-7/policy.xml

# Imagick version
RUN php -r 'var_dump(Imagick::getVersion());'

# Imagick formats
RUN php -r 'var_dump(Imagick::queryFormats());'

# Update ulimit
RUN ulimit -n 16384
