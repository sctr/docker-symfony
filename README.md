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

## Useful Links

- https://github.com/mvorisek/image-php/tree/master
- https://github.com/dunglas/frankenphp
