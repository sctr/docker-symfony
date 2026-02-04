# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1-php8.5-trixie

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf"

ENV BUILD_DEPS="make git autoconf wget"

COPY --link --chmod=755 ./8.5-frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

WORKDIR /app

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

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
        libnss3-tools \
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

# Copying manifest files to host
COPY ./8.5-frankenphp/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml