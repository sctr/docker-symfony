ARG PHP_VERSION
FROM php:$PHP_VERSION-fpm-alpine

ENV ENVIRONMENT=prod
ENV REQUIRED_PACKAGES="zlib zlib-dev curl supervisor pcre linux-headers go postgresql-dev mysql-dev"
ENV DEVELOPMENT_PACKAGES="git zip autoconf g++ make openssh-client tar python py-pip pcre-dev"
ENV PECL_PACKAGES="redis apcu"
ENV EXT_PACKAGES="zip sockets pdo_pgsql pdo_mysql"

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_CACHE_DIR /tmp
ENV GOPATH="/root/go"

# Install Packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES $DEVELOPMENT_PACKAGES

# Install Supervisor
RUN pip install supervisor-stdout

# Install Webserver
RUN mkdir -p $GOPATH/src \
    && cd $GOPATH/src \
    && go get -u github.com/mholt/caddy \
    && go get -u github.com/caddyserver/builds \
    && cd $GOPATH/src/github.com/mholt/caddy/caddy \
    && git checkout tags/v0.11.0 \
    && go run build.go -goos=linux -goarch=amd64 \
    && mv caddy /usr/local/sbin/caddy

# Install Pecl Packages
RUN yes '' | pecl install -f $PECL_PACKAGES
RUN docker-php-ext-enable $PECL_PACKAGES

# Install Non-Pecl Packages
RUN docker-php-ext-install $EXT_PACKAGES

# Download composer
RUN curl --silent --show-error https://getcomposer.org/installer | php \
    && mv composer.phar /usr/bin/composer

WORKDIR $WORKDIR
COPY $COPY_FILES /app

# Create, and chmod the var dir
RUN mkdir -p ./var/cache ./var/logs \
    && chmod -R 2777 ./var

# Delete Non-Required Packages
RUN apk del $DEVELOPMENT_PACKAGES

# Copying manifest files to host
COPY ./manifest /

CMD /usr/bin/supervisord -n -c /etc/supervisord.conf
