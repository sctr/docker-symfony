ARG CADDY_VERSION=2.11
ARG FRANKENPHP_VERSION=1.11.3

FROM caddy:${CADDY_VERSION}-builder AS caddy-builder

# -----------------------------------------------------
# FrankenPHP Build
# -----------------------------------------------------
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-builder-php8.5-trixie AS builder

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
    --with github.com/ggicci/caddy-jwt@v1.1.2 \
    --with github.com/mholt/caddy-ratelimit@v0.1.0 \
    --with github.com/pberkel/caddy-storage-redis@v1.7.0 \
    --with github.com/sctr/frankenphp-tailwind-merge

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php8.5-trixie

# Replace the official binary with the one containing custom modules
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif gd gettext gmp igbinary imagick intl opcache pcntl redis mongodb sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf opentelemetry"

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

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Copying manifest files to host
COPY ./8.5-www/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml