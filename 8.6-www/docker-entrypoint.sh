#!/bin/sh
set -e

if [ "${INSTALL_COMPOSER_DEPS:-0}" = "1" ] && [ -z "$(ls -A 'vendor/' 2>/dev/null)" ]; then
	composer install --prefer-dist --no-progress --no-interaction
fi

exec docker-php-entrypoint "$@"
