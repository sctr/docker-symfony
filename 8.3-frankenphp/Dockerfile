# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1-php8.3

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
        acl \
        file \
        gettext \
        gifsicle \
        git \
        imagemagick \
        jpegoptim \
        optipng \
        pngquant \
        procps \
        supervisor \
        webp \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	install-php-extensions \
        @composer \
        amqp \
        apcu \
        igbinary \
        exif \
        ffi \
        gd \
        imagick \
        intl \
        opcache \
        uuid \
        zip \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        pcntl \
        redis \
        vips \
	;

# Copying manifest files to host
COPY ./8.3-frankenphp/manifest /