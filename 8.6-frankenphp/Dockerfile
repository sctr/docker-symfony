ARG PHP_VERSION=8.6.0RC5
ARG FRANKENPHP_VERSION=1.13.5
ARG GO_VERSION=1.27
ARG WATCHER_VERSION=0.14.5

# FrankenPHP does not publish PHP 8.6 images yet, so it is compiled here following
# its upstream Dockerfile. Since PHP 8.6 every official php image is built as ZTS
# with the embed SAPI (the separate "-zts" variant was dropped), so the "cli"
# variant is the FrankenPHP base.
FROM golang:${GO_VERSION}-trixie AS golang-base

# -----------------------------------------------------
# FrankenPHP Build
# -----------------------------------------------------
FROM php:${PHP_VERSION}-cli-trixie AS builder

ARG FRANKENPHP_VERSION
ARG WATCHER_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=golang-base /usr/local/go /usr/local/go

ENV PATH=/usr/local/go/bin:$PATH
ENV GOTOOLCHAIN=local

RUN apt-get update && apt-get -y --no-install-recommends install \
        cmake \
        git \
        libargon2-dev \
        libbrotli-dev \
        libcap2-bin \
        libcurl4-openssl-dev \
        libonig-dev \
        libreadline-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
	&& rm -rf /var/lib/apt/lists/*

# e-dant/watcher (FrankenPHP file watching)
WORKDIR /usr/local/src/watcher
RUN curl -fsSL "https://github.com/e-dant/watcher/archive/refs/tags/release/${WATCHER_VERSION}.tar.gz" | tar xz --strip-components 1 \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build \
    && cmake --install build \
    && ldconfig

WORKDIR /go/src/app
RUN git clone --depth 1 --branch "v${FRANKENPHP_VERSION}" https://github.com/php/frankenphp.git . \
    && go mod download \
    && cd caddy && go mod download

# See https://github.com/docker-library/php/blob/master/8.6-rc/trixie/cli/Dockerfile for PHP values
ENV CGO_CFLAGS="-DFRANKENPHP_VERSION=$FRANKENPHP_VERSION $PHP_CFLAGS"
ENV CGO_CPPFLAGS=$PHP_CPPFLAGS
ENV CGO_LDFLAGS="-L/usr/local/lib -lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS"

WORKDIR /go/src/app/caddy/frankenphp
RUN GOBIN=/usr/local/bin \
    ../../go.sh install -ldflags "-w -s -X 'github.com/caddyserver/caddy/v2.CustomVersion=FrankenPHP v$FRANKENPHP_VERSION PHP $PHP_VERSION Caddy' -X 'github.com/caddyserver/caddy/v2.CustomBinaryName=frankenphp' -X 'github.com/caddyserver/caddy/v2/modules/caddyhttp.ServerHeader=FrankenPHP Caddy'" -buildvcs=false \
    && setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp \
    && frankenphp version \
    && frankenphp build-info

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM php:${PHP_VERSION}-cli-trixie

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"
# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME=/config XDG_DATA_HOME=/data
ENV GODEBUG=cgocheck=0

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
        mailcap \
        libcap2-bin \
        # Runtime libraries of the webp tools unpacked below
        libgif7 libjpeg62-turbo libpng16-16t64 libsharpyuv0 libtiff6 libwebp7 libwebpdemux2 libwebpmux3 \
    # The webp package depends on OpenGL (~200 MB of Mesa and LLVM) only for its vwebp viewer:
    # unpack its command-line tools instead of installing it.
    && cd /tmp && apt-get download webp \
    && dpkg-deb --fsys-tarfile webp_*.deb | tar -x -C / \
        ./usr/bin/cwebp ./usr/bin/dwebp ./usr/bin/gif2webp ./usr/bin/img2webp ./usr/bin/webpinfo ./usr/bin/webpmux \
    && rm webp_*.deb \
	&& rm -rf /var/lib/apt/lists/*

# Same layout as the upstream FrankenPHP image
RUN set -eux; \
    mkdir -p /app/public /config/caddy /data/caddy /etc/caddy /etc/frankenphp; \
    sed -i 's/php/frankenphp run/g' /usr/local/bin/docker-php-entrypoint

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
ARG VIPS_VERSION=8.18.7
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

ARG PHPREDIS_REF=623e8db5a39657ba7218ceea81ab8338d248b036
COPY --chmod=755 scripts/install-phpredis.sh /tmp/install-phpredis.sh
RUN /tmp/install-phpredis.sh ${PHPREDIS_REF} && rm /tmp/install-phpredis.sh

# Keep frequently changing binaries and startup code after dependency installation.
COPY --from=builder /usr/local/lib/libwatcher* /usr/local/lib/
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp
# The builder stage sets cap_net_bind_service, which COPY keeps: running setcap here would
# rewrite the binary into another layer and store it twice.
RUN ldconfig \
    && frankenphp version
COPY --from=composer/composer:2-bin /composer /usr/bin/composer
COPY --link --chmod=755 ./8.6-frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

# Copying manifest files to host
COPY ./8.6-frankenphp/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
