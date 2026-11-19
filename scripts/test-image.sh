#!/bin/sh
# Usage: sh scripts/test-image.sh IMAGE 8.2|8.2-debian|8.3|8.4|8.5|8.5-www|8.5-frankenphp
set -eu

docker run --rm --network none --read-only "$1" php -v

docker run --rm --network none --read-only --tmpfs /tmp:exec --entrypoint sh "$1" -eu -c '
    # Legacy images (8.2-8.4) are PHP-FPM + Caddy; only 8.4 and 8.5 ship libvips.
    case "$1" in *frankenphp|8.5-www) fpm=0 ;; *) fpm=1 ;; esac
    case "$1" in 8.2*|8.3*|8.5-www) vips=0 ;; *) vips=1 ;; esac
    php -r '\''
        foreach (explode(" ", getenv("EXTENSIONS")) as $extension) {
            // GitHub sources: "vendor/php-ext-name@ref" loads as "name".
            $extension = preg_replace("~^.*/(php-ext-)?|@.*$~", "", $extension);
            if (!extension_loaded($extension === "opcache" ? "Zend OPcache" : $extension)) {
                throw new RuntimeException("Missing extension: " . $extension);
            }
        }
        // Older images misspell this ini key, so only 8.5 images enable it.
        if (str_starts_with($argv[1], "8.5") && ini_get("opcache.enable_file_override") !== "1") {
            throw new RuntimeException("OPcache file override is disabled");
        }
        $image = new Imagick();
        $image->newImage(8, 8, "white");
        $image->setImageFormat("png");
        $image->writeImage("/tmp/imagick.png");
    '\'' "$1"
    composer --version
    if [ "$vips" = 1 ]; then
        test "$(dpkg-query -W -f '\''${db:Status-Status}'\'' libvips-dev 2>/dev/null || true)" != installed
        vips --version
        vips black /tmp/test.v 8 8
        for format in png jpg webp tiff; do
            vips copy /tmp/test.v "/tmp/test.$format"
            vipsheader "/tmp/test.$format"
        done
    fi
    if [ "$fpm" = 1 ]; then
        php-fpm -t
        caddy version
        if [ "$1" = "8.5" ]; then
            caddy list-modules | grep -q http.encoders.br
        fi
    else
        frankenphp list-modules > /tmp/modules
        modules="frankenphp http.encoders.br"
        if [ "$1" = "8.5-www" ]; then
            modules="$modules http.authentication.providers.jwt http.handlers.rate_limit caddy.storage.redis"
        fi
        for module in $modules; do
            grep -qx "$module" /tmp/modules
        done

        # Exercise startup with no network and stub only the external commands.
        mkdir -p /tmp/bin /tmp/app
        printf "#!/bin/sh\necho installed > /tmp/composer-called\n" > /tmp/bin/composer
        printf "#!/bin/sh\nexit 0\n" > /tmp/bin/docker-php-entrypoint
        chmod +x /tmp/bin/*
        export PATH="/tmp/bin:$PATH"
        cd /tmp/app
        unset INSTALL_COMPOSER_DEPS
        docker-entrypoint php -v
        test ! -e /tmp/composer-called
        INSTALL_COMPOSER_DEPS=1 docker-entrypoint php -v
        test -e /tmp/composer-called
        rm /tmp/composer-called
        mkdir vendor
        touch vendor/autoload.php
        INSTALL_COMPOSER_DEPS=1 docker-entrypoint php -v
        test ! -e /tmp/composer-called
        rm vendor/autoload.php
        printf "#!/bin/sh\nexit 42\n" > /tmp/bin/composer
        status=0
        INSTALL_COMPOSER_DEPS=1 docker-entrypoint php -v || status=$?
        test "$status" -eq 42
    fi
' sh "$2"
