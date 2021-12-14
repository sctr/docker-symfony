ARG PHP_VERSION=8.0
ARG RR_VERSION=2.6.0
ARG RR_IMAGE=spiralscout/roadrunner:${RR_VERSION}

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:${PHP_VERSION}-cli-alpine

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR

ENV REQUIRED_PACKAGES="git make zip libzip curl supervisor python3 ca-certificates pcre linux-headers gettext-dev mysql-dev postgresql-dev rabbitmq-c icu libsodium-dev oniguruma-dev libjpeg-turbo-dev freetype-dev libpng-dev libwebp libwebp-dev libpng freetype libjpeg-turbo jpegoptim optipng pngquant gifsicle imagemagick libmaxminddb"
ENV DEVELOPMENT_PACKAGES="autoconf g++ openssh-client tar py-pip pcre-dev rabbitmq-c-dev icu-dev zlib-dev libzip-dev libmaxminddb-dev"
ENV PICKLE_PACKAGES="amqp apcu ast"
ENV PECL_PACKAGES="redis mongodb maxminddb"
ENV EXT_PACKAGES="zip sockets pdo_mysql pdo_pgsql bcmath opcache mbstring iconv gettext intl exif sodium gd pcntl sysvmsg sysvsem sysvshm"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_CACHE_DIR /tmp

WORKDIR /app

# Copying manifest files to host
COPY ./8.0-rr/manifest /

# Copy RoadRunner
COPY --from=${RR_IMAGE} /usr/bin/rr /usr/bin/rr

# Copy Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install Packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES $DEVELOPMENT_PACKAGES

# Update ulimit
RUN ulimit -n 16384

# Fix Iconv
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# Configure GD to use freetype fonts
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# Install Non-Pecl Packages
RUN docker-php-ext-install $EXT_PACKAGES

# Install Pecl Packages
RUN apk add --no-cache $PHPIZE_DEPS && wget https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar && mv pickle.phar /usr/local/bin/pickle && chmod +x /usr/local/bin/pickle
RUN for package in $PICKLE_PACKAGES; do pickle install $package --defaults; done
RUN yes '' | pecl install -f $PECL_PACKAGES; \
    docker-php-ext-enable $PECL_PACKAGES

# Imagick from master @TODO upgrade to release version when php8 support is ready
RUN docker-php-source extract \
    && mkdir /usr/src/php/ext/imagick \
    && curl -L https://github.com/Imagick/imagick/archive/master.tar.gz | tar -xzC /usr/src/php/ext/imagick --strip-components=1 \
    && docker-php-ext-install imagick \
    && docker-php-source delete

# Delete Non-Required Packages
RUN apk del $DEVELOPMENT_PACKAGES
