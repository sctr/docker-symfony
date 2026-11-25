# -----------------------------------------------------
# libvips (built apart from PHP so it caches and compiles in parallel)
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
# -----------------------------------------------------
FROM debian:trixie-slim AS libvips
ARG VIPS_VERSION=8.18.7
COPY --chmod=755 scripts/build-libvips.sh /tmp/build-libvips.sh
RUN /tmp/build-libvips.sh ${VIPS_VERSION}

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1.13.6-php8.5-trixie

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip opentelemetry zstd-0.18.0 symfony/php-ext-deepclone@v0.8.9"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
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

# Keep frequently changing binaries and startup code after dependency installation.
COPY --from=composer/composer:2-bin /composer /usr/bin/composer
COPY --link --chmod=755 ./8.5-frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

# Copying manifest files to host
COPY ./8.5-frankenphp/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
