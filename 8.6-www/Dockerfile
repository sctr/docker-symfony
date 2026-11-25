ARG CADDY_VERSION=2.11
ARG FRANKENPHP_VERSION=1.14.0
ARG PHP_VERSION=8.6.0

FROM caddy:${CADDY_VERSION}-builder AS caddy-builder

# -----------------------------------------------------
# FrankenPHP Build
# -----------------------------------------------------
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-builder-php${PHP_VERSION}-trixie AS builder

ARG FRANKENPHP_VERSION

# Copy xcaddy from caddy builder
COPY --from=caddy-builder /usr/bin/xcaddy /usr/bin/xcaddy

# Build FrankenPHP with custom Caddy modules
RUN CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS=$(php-config --includes) \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
    --output /usr/local/bin/frankenphp \
    --with github.com/dunglas/frankenphp@v${FRANKENPHP_VERSION}=./ \
    --with github.com/dunglas/frankenphp/caddy@v${FRANKENPHP_VERSION}=./caddy/ \
    --with github.com/dunglas/caddy-cbrotli@v1.0.1 \
    #caddy-jwt 1.2.0
    --with github.com/ggicci/caddy-jwt@28e0de3db362a787564352ec22e97aa743a371f3 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/pberkel/caddy-storage-redis@v1.7.0

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-trixie

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

# PHP 8.6 removed internal C APIs (XtOffsetOf, zval_dtor, INI_STR/INT/FLT, ...). Until PECL releases
# support 8.6: apcu (5.1.29 release commit, not on PECL), igbinary and imagick are built from pinned
# upstream commits, amqp from the sctr/php-amqp fork (php-8.6-support branch, pending upstream),
# redis by scripts/install-phpredis.sh, and protobuf and grpc are left out because no upstream code
# compiles on 8.6 yet.
ENV EXTENSIONS="sctr/php-amqp@7a4318b41915d8957ab207de43783d94db25aa25 krakjoe/apcu@66300e28647c16fef7672a5add532f4262b23a75 ast bcmath exif gd gettext gmp igbinary/igbinary@2b1f5d62e3037b07c2a46499ac32091cdb41fb40 Imagick/imagick@55ed2e9fda264395636a2e27e51f31673f5566ab intl mbstring opcache pcntl mongodb sockets sysvmsg sysvsem sysvshm uuid xsl zip opentelemetry zstd-0.18.0 symfony/php-ext-deepclone@v0.8.13"

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
        gifsicle \
        jpegoptim \
        optipng \
        pngquant \
        libnss3-tools \
        # Runtime libraries of the webp tools unpacked below
        libgif7 libjpeg62-turbo libpng16-16t64 libsharpyuv0 libtiff6 libwebp7 libwebpdemux2 libwebpmux3 \
    # The webp package depends on OpenGL (~200 MB of Mesa and LLVM) only for its vwebp viewer:
    # unpack its command-line tools instead of installing it.
    && cd /tmp && apt-get download webp \
    && dpkg-deb --fsys-tarfile webp_*.deb | tar -x -C / \
        ./usr/bin/cwebp ./usr/bin/dwebp ./usr/bin/gif2webp ./usr/bin/img2webp ./usr/bin/webpinfo ./usr/bin/webpmux \
    && rm webp_*.deb \
	&& rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

ARG PHPREDIS_REF=623e8db5a39657ba7218ceea81ab8338d248b036
COPY --chmod=755 scripts/install-phpredis.sh /tmp/install-phpredis.sh
RUN /tmp/install-phpredis.sh ${PHPREDIS_REF} && rm /tmp/install-phpredis.sh

# Keep frequently changing binaries and startup code after dependency installation.
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=composer/composer:2-bin /composer /usr/bin/composer
COPY --link --chmod=755 ./8.6-www/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

# Copying manifest files to host
COPY ./8.6-www/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
