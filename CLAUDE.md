# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker images for PHP/Symfony applications. Provides production-ready containers with PHP-FPM + Caddy or FrankenPHP, optimized for Symfony development.

**Registry:** `ghcr.io/sctr/docker-symfony`

## Build Commands

```bash
# Build a specific image locally
docker build -f 8.4/Dockerfile -t docker-symfony:8.4 .
docker build -f 8.4-frankenphp/Dockerfile -t docker-symfony:8.4-frankenphp .

# Build with cache from registry
docker pull ghcr.io/sctr/docker-symfony:8.4-amd64 || true
docker build --cache-from ghcr.io/sctr/docker-symfony:8.4-amd64 -f 8.4/Dockerfile -t docker-symfony:8.4 .
```

## Architecture

### Image Variants

Two types of images:

1. **PHP-FPM + Caddy** (directories: `8.4/`, `8.5/`)
   - Multi-stage build: first stage builds Caddy with custom modules, second stage sets up PHP-FPM
   - Process management via Supervisor (runs both PHP-FPM and Caddy)
   - Caddy modules: `caddy-ratelimit`, `caddy-storage-redis`, `caddy-jwt`

2. **FrankenPHP** (directories: `8.4-frankenphp/`, `8.5-frankenphp/`)
   - Single binary combining PHP and HTTP server
   - Uses `dunglas/frankenphp` base image
   - Custom `docker-entrypoint.sh` for initialization

### Directory Structure Pattern

Each PHP version directory contains:
- `Dockerfile` - Multi-stage build definition
- `manifest/` - Configuration templates copied into the container:
  - `etc/caddy/Caddyfile` or `etc/frankenphp/Caddyfile` - Web server config
  - `etc/supervisord.conf` - Process manager config
  - `etc/supervisor/conf.d/*.conf` - Individual service configs
  - `usr/local/etc/php/app.conf.d/10-*.ini` - PHP configuration files
  - `IM7-policy.xml` - ImageMagick security policy (8.4+)

### Key Environment Variables

```dockerfile
PORT=9001                              # Application port
PUBLIC_DIR=public                      # Web root directory
PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"  # PHP config scan directory
```

### PHP Extensions (common across versions)

`amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf`

Note: `grpc` is excluded from PHP 8.5 FrankenPHP due to compatibility issues.

## CI/CD

GitHub Actions workflow (`.github/workflows/build-and-push.yml`) builds multi-arch images:

- **Active versions:** 8.4, 8.4-frankenphp, 8.5, 8.5-frankenphp
- **Architectures:** AMD64 + ARM64
- **Output tags:** `ghcr.io/sctr/docker-symfony:{version}[-{arch}]`

Legacy versions (8.2, 8.3) require manual builds.

## Adding a New PHP Version

1. Copy an existing version directory (e.g., `cp -r 8.5 8.6`)
2. Update the `Dockerfile`:
   - Change `ARG PHP_VERSION` or base image tag
   - Adjust extensions if needed for compatibility
3. Update manifest files if PHP config changes are needed
4. Add the new version to `.github/workflows/build-and-push.yml` matrix
