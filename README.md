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
| `8.6` | Debian + PHP-FPM + Caddy | PHP 8.6 (RC) with Caddy reverse proxy, without amqp/grpc/protobuf (see below) |
| `8.6-frankenphp` | FrankenPHP (built from source) | PHP 8.6 (RC) with FrankenPHP (single binary), without amqp/protobuf (see below) |
| `8.6-www` | FrankenPHP (built from source) + Custom Caddy | PHP 8.6 (RC) FrankenPHP with Caddy modules (ratelimit, redis, jwt), without amqp/grpc/protobuf (see below) |
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

### PHP 8.6 images

The 8.6 images track the PHP 8.6 release candidates (currently `8.6.0RC4`) until 8.6.0 is
released; bump `PHP_VERSION` in the three 8.6 Dockerfiles to follow new releases.

They mirror the 8.5 images (same ini files, entrypoints and Caddy modules), except:

- **Extensions:** PHP 8.6 removed internal C APIs (`XtOffsetOf()`, `zval_dtor()`, `INI_STR/INT/FLT`,
  `zval_is_true()`, the `php_verror()` `param` argument), and several PECL extensions have no
  8.6-compatible release yet. Until they do:
  - `apcu` (5.1.29 release commit, not yet on PECL), `igbinary` and `imagick` are built from pinned
    upstream commits listed in `EXTENSIONS`;
  - `redis` is built from a pinned phpredis commit by `scripts/install-phpredis.sh` (`PHPREDIS_REF`),
    because its GitHub source lacks the `liblzf` submodule that `install-php-extensions` needs;
  - **`amqp`, `protobuf` and `grpc` are not included**: no upstream code compiles on PHP 8.6 yet.

  Switch back to the PECL releases, and restore the missing extensions (and `10-grpc.ini`), once
  releases support 8.6.

- Since PHP 8.6 the official `php` images are all built as ZTS with the embed SAPI, and the
  separate `-zts` tag no longer exists, so `8.6-frankenphp` and `8.6-www` are based on
  `php:8.6.*-cli-trixie`.
- FrankenPHP does not publish PHP 8.6 images yet, so both FrankenPHP variants compile
  FrankenPHP (`FRANKENPHP_VERSION`) and e-dant/watcher (`WATCHER_VERSION`) in a builder stage,
  following the upstream FrankenPHP Dockerfile. `8.6-frankenphp` includes the same Caddy modules
  as the upstream binary (Mercure, Vulcain, brotli). `8.6-www` adds the jwt, ratelimit and
  redis storage modules through xcaddy, as `8.5-www` does.

```bash
sh scripts/test-image.sh docker-symfony:8.6 8.6
sh scripts/test-image.sh docker-symfony:8.6-www 8.6-www
sh scripts/test-image.sh docker-symfony:8.6-frankenphp 8.6-frankenphp
```

## Useful Links

- https://github.com/mvorisek/image-php/tree/master
- https://github.com/dunglas/frankenphp
