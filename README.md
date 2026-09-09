# Docker Symfony

Production-ready Docker images for PHP/Symfony applications with PHP-FPM + Caddy or FrankenPHP.

## Available Images

Pull from GitHub Container Registry:

```bash
docker pull ghcr.io/sctr/docker-symfony:{tag}
```

### Active Images (Multi-arch: AMD64 + ARM64)

| Tag | Base | Description |
|-----|------|-------------|
| `8.5` | Debian + PHP-FPM + Caddy | PHP 8.5 with Caddy reverse proxy |
| `8.5-frankenphp` | FrankenPHP | PHP 8.5 with FrankenPHP (single binary) |
| `8.5-www` | FrankenPHP + Custom Caddy | PHP 8.5 FrankenPHP with Caddy modules (ratelimit, redis, jwt) |
| `8.4` | Debian + PHP-FPM + Caddy | PHP 8.4 with Caddy reverse proxy |

Architecture-specific tags are also available: `8.4-amd64`, `8.4-arm64`, etc.

### Legacy Images (Manual builds only)

| Tag | Base | Description |
|-----|------|-------------|
| `8.4-frankenphp` | FrankenPHP | PHP 8.4 with FrankenPHP |
| `8.3` | Alpine + PHP-FPM + Caddy | PHP 8.3 (Alpine-based) |
| `8.3-frankenphp` | FrankenPHP | PHP 8.3 with FrankenPHP |
| `8.2` | Alpine + PHP-FPM + Caddy | PHP 8.2 (Alpine-based) |
| `8.2-debian` | Debian + PHP-FPM + Caddy | PHP 8.2 (Debian-based) |

## Features

- **Web Servers:** Caddy with custom modules (rate limiting, Redis storage, JWT auth) or FrankenPHP
- **Process Management:** Supervisor for multi-process orchestration
- **Image Processing:** ImageMagick 7, libvips 8.18, jpegoptim, optipng, pngquant, gifsicle, webp
- **PHP Extensions:** amqp, apcu, bcmath, gd, grpc, imagick, intl, mongodb, opcache, pdo_mysql, pdo_pgsql, redis, uuid, and more

## Usage

```dockerfile
FROM ghcr.io/sctr/docker-symfony:8.5

WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader
```

Default ports: 80 (HTTP), 9001 (configurable via `PORT` env)

### PHP 8.5 production builds

Install Composer dependencies in the downstream application image, as above.
The `8.5-www` and `8.5-frankenphp` entrypoints no longer install dependencies by default. For development
set `INSTALL_COMPOSER_DEPS=1` to restore installation when `vendor/` is empty.

All three PHP 8.5 images retain Git for Composer source installs, the upstream PHP build tools
for downstream extension builds, and their existing PHP extensions. Removing files
inherited from a base image does not reclaim its layers; removing that toolchain or
the original FrankenPHP binary requires a different runtime base.

`8.5` and `8.5-frankenphp` retain libvips 8.18.2, but their shared installer removes newly installed build
dependencies after preserving runtime libraries. This cleanup also applies to the
other variants using `scripts/install-libvips.sh`.

OPcache timestamp validation remains enabled for applications that update files in
place. Immutable production deployments can add `opcache.validate_timestamps=0`
to an application INI file, provided they restart the container on every code change.
Set file descriptor limits at deployment time (for example, Docker's
`--ulimit nofile=16384:16384`); a Dockerfile `RUN ulimit` does not persist them.

CI validates pull requests without publishing images. Master builds publish images
and a separate registry build cache per variant and architecture, including builder
stages. To run the image smoke checks locally:

```bash
sh scripts/test-image.sh docker-symfony:8.5 8.5
sh scripts/test-image.sh docker-symfony:8.5-www 8.5-www
sh scripts/test-image.sh docker-symfony:8.5-frankenphp 8.5-frankenphp
```

## Useful Links

- https://github.com/mvorisek/image-php/tree/master
- https://github.com/dunglas/frankenphp
