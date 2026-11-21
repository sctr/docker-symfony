#!/bin/bash
# Builds libvips into /usr/local inside a throwaway Debian stage, so it caches
# and compiles independently of the PHP base image. Writes the Debian packages
# its binaries need at runtime to /vips-runtime-packages for the final image.
set -euxo pipefail

VIPS_VERSION="$1"
# libvips-dev pulls in Debian's libvips; on arm64 its directory sorts before /usr/local/lib
# in ld.so.conf.d, so prefer ours explicitly (the final images set the same variable).
export LD_LIBRARY_PATH=/usr/local/lib

apt-get -y update
apt-get install -y --no-install-recommends build-essential ninja-build meson wget ca-certificates xz-utils pkg-config libvips-dev

cd /tmp
wget -q "https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz"
tar xf "vips-${VIPS_VERSION}.tar.xz"
cd "vips-${VIPS_VERSION}"

meson setup build --prefix /usr/local --libdir lib --buildtype release
meson compile -C build
meson install -C build
ldconfig

# Runtime libraries used by the installed binaries and libvips' dynamically loaded modules.
find /usr/local -type f \( -name '*.so*' -o -executable \) -exec ldd '{}' ';' 2>/dev/null \
    | awk '/=> \/(usr\/)?lib\// { print $(NF-1) }' \
    | xargs -r readlink -f \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u > /vips-runtime-packages

vips --version
