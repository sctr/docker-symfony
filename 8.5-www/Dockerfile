# -----------------------------------------------------
# Caddy Modules Builder
# -----------------------------------------------------
FROM dunglas/frankenphp:builder-php8.5-bookworm AS builder

# Copy xcaddy from caddy builder
COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

# Build FrankenPHP with custom Caddy modules
RUN CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS=$(php-config --includes) \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
    --output /usr/local/bin/frankenphp \
    --with github.com/dunglas/frankenphp=./ \
    --with github.com/dunglas/frankenphp/caddy=./caddy/ \
    --with github.com/mholt/caddy-ratelimit \
    --with github.com/pberkel/caddy-storage-redis \
    --with github.com/ggicci/caddy-jwt

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1-php8.5

# Replace the official binary with the one containing custom modules
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip"

ENV BUILD_DEPS="make git autoconf wget"

COPY --link --chmod=755 ./8.5-www/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

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

####################################################################################################
# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
####################################################################################################
ARG VIPS_VERSION=8.18.0
ENV VIPS_BUILD_DEPS="build-essential ninja-build meson wget pkg-config"
ENV VIPS_DEPS="libvips-dev"
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get remove --autoremove --purge -y libvips && \
    apt-get install -y --no-install-recommends ${VIPS_BUILD_DEPS} ${VIPS_DEPS} && \
    cd /usr/local/src && wget https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz && \
    xz -d -v vips-${VIPS_VERSION}.tar.xz && tar xf vips-${VIPS_VERSION}.tar && \
    cd vips-${VIPS_VERSION} && \
    meson setup build --libdir lib && meson compile -C build && meson install -C build && \
    apt-get remove --autoremove --purge -y ${VIPS_BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/src/vips-*

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Copy Imagemagick policy
COPY /8.5/manifest/IM7-policy.xml /etc/ImageMagick-7/policy.xml

# Imagick version
RUN php -r 'var_dump(Imagick::getVersion());'

# Imagick formats
RUN php -r 'var_dump(Imagick::queryFormats());'

# Copying manifest files to host
COPY ./8.5-www/manifest /