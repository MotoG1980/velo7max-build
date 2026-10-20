#!/usr/bin/env bash
# Build OpenWrt snapshot for the LTC Velo7 Max from z21100644/openwrt@velo7max-fixes.
# Usage: ./build.sh [workdir]      (needs ~30 GB free, a non-root user, Debian/Ubuntu host)
set -euo pipefail

REPO=https://github.com/z21100644/openwrt.git
BRANCH=velo7max-fixes
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${1:-$HERE/openwrt}"
JOBS="${JOBS:-$(nproc)}"

if [ ! -d "$WORK/.git" ]; then
  git clone -b "$BRANCH" "$REPO" "$WORK"
else
  git -C "$WORK" fetch origin "$BRANCH" && git -C "$WORK" checkout -B "$BRANCH" "origin/$BRANCH"
fi
cd "$WORK"

echo ">> U-Boot in tree: $(grep '^PKG_VERSION' package/boot/uboot-mediatek/Makefile)"

./scripts/feeds update -a
./scripts/feeds install -a

cp "$HERE/velo7max.config" .config
make defconfig

make download -j8
# Retry single-threaded with verbose output if the parallel build fails,
# so the real error is visible at the end of the log.
make -j"$JOBS" || make -j1 V=s

echo ">> Images:"
ls -lh bin/targets/mediatek/filogic/*ltc_vl7m19k*
