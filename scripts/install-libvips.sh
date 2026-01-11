#!/bin/bash
set -eux

VIPS_VERSION="${1:-8.18.0}"

VIPS_BUILD_DEPS="build-essential ninja-build meson wget pkg-config"
VIPS_DEPS="libvips-dev"

apt-get -y update
apt-get -y upgrade
apt-get remove --autoremove --purge -y libvips || true
apt-get install -y --no-install-recommends ${VIPS_BUILD_DEPS} ${VIPS_DEPS}

cd /usr/local/src
wget https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz
xz -d -v vips-${VIPS_VERSION}.tar.xz
tar xf vips-${VIPS_VERSION}.tar
cd vips-${VIPS_VERSION}

meson setup build --libdir lib
meson compile -C build
meson install -C build

# Cleanup
apt-get remove --autoremove --purge -y ${VIPS_BUILD_DEPS}
rm -rf /var/lib/apt/lists/*
rm -rf /usr/local/src/vips-*
