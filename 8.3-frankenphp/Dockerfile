ARG PHP_VERSION=8.3

# -----------------------------------------------------
# Caddy / FrankenPHP Build
# -----------------------------------------------------
FROM dunglas/frankenphp:1-builder-php$PHP_VERSION AS builder

# Copy xcaddy in the builder image
COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

# CGO must be enabled to build FrankenPHP
ENV CGO_ENABLED=1 XCADDY_SETCAP=1 XCADDY_GO_BUILD_FLAGS="-ldflags '-w -s'"
RUN xcaddy build \
	--output /usr/local/bin/frankenphp \
	--with github.com/dunglas/frankenphp=./ \
	--with github.com/dunglas/frankenphp/caddy=./caddy/ \
	--with github.com/dunglas/caddy-cbrotli
	# Add extra Caddy modules here \

# -----------------------------------------------------
# FrankenPHP
#------------------------------------------------------
FROM dunglas/frankenphp:1-php$PHP_VERSION

# Replace the official binary by the one contained your custom modules
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

ARG PORT=9001

ENV PORT=$PORT SERVER_NAME=":80, :$PORT"
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
	procps \
	acl \
	file \
	gettext \
	git \
    imagemagick \
    supervisor \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	install-php-extensions \
		@composer \
		amqp \
		apcu \
		intl \
    	igbinary \
        gd \
        imagick/imagick@master  \
		redis \
		opcache \
        uuid \
        vips \
        zip \
	;

# Copying manifest files to host
COPY ./8.3-frankenphp/manifest /