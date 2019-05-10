ARG PHP_VERSION

# -----------------------------------------------------
# Caddy Install
# -----------------------------------------------------
FROM alpine as caddy

ARG plugins=http.git,http.cache,http.expires,http.minify,http.realip

RUN apk --update add git curl linux-headers

RUN curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://caddyserver.com/download/linux/amd64?plugins=${plugins}&license=personal&telemetry=off" \
    | tar --no-same-owner -C /tmp -xz caddy \
    && chmod 0755 /tmp/caddy

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm-alpine

ENV ENVIRONMENT=dev

ENV REQUIRED_PACKAGES="zlib-dev libzip-dev zip curl supervisor pcre linux-headers gettext-dev mysql-dev postgresql-dev rabbitmq-c php7-amqp icu"
ENV DEVELOPMENT_PACKAGES="git autoconf g++ make openssh-client tar python py-pip pcre-dev rabbitmq-c-dev icu-dev"
ENV PECL_PACKAGES="redis amqp apcu"
ENV EXT_PACKAGES="zip sockets pdo_mysql pdo_pgsql bcmath opcache mbstring iconv gettext intl exif"

ENV DOCKER=true
ENV LOCAL_VM=$LOCAL_VM
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_CACHE_DIR /tmp

WORKDIR /app

# Copying manifest files to host
COPY ./manifest /
COPY --from=caddy /tmp/caddy /usr/local/sbin/caddy

# Install Packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES $DEVELOPMENT_PACKAGES

# Install Supervisor
RUN pip install supervisor-stdout

# Install Pecl Packages
RUN yes '' | pecl install -f $PECL_PACKAGES
RUN docker-php-ext-enable $PECL_PACKAGES

# Install Non-Pecl Packages
RUN docker-php-ext-install $EXT_PACKAGES

# Download composer
RUN curl --silent --show-error https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer

# Create, and chmod the var dir
RUN mkdir -p ./var/cache/$ENVIRONMENT ./var/log \
    && chmod -R 2777 ./var

# Optimize Opcache in non-dev
RUN if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "development" ]]; then printf "\nopcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini; fi

# Delete Non-Required Packages
RUN apk del $DEVELOPMENT_PACKAGES

# Create, and chmod the var dir
RUN mkdir -p ./var/cache ./var/log \
    && chmod -R 2777 ./var
