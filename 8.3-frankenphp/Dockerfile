# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1-php8.3

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

COPY --link --chmod=755 ./8.3-frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

WORKDIR /app

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

RUN set -eux; \
	install-php-extensions \
        @composer \
        amqp \
        apcu \
        bcmath \
        exif \
        ffi \
        gd \
        gmp \
        igbinary \
        imagick \
        intl \
        maxminddb \
        mongodb \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        redis \
        sockets \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        uuid \
        xsl \
        zip \
	;

# Copying manifest files to host
COPY ./8.3-frankenphp/manifest /