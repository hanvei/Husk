#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Reuse the official 2.0 IPA's unchanged binary dependencies and guest resources.
# The app, extensions, native translation layer and pairing library are rebuilt.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED="${1:?path to extracted official Husk.app required}"
mkdir -p "$ROOT/build/ios-arm64/lib" "$ROOT/build/ios-arm64/sysroot/lib" \
  "$ROOT/guests/phase0" "$ROOT/third_party/build/qemu-10.0.12-utm/pc-bios"
for lib in libqemu-aarch64-softmmu.dylib libANGLE-shared.dylib; do
  test -f "$SEED/Frameworks/$lib"
done
cp "$SEED/Frameworks/libqemu-aarch64-softmmu.dylib" "$ROOT/build/ios-arm64/lib/"
cp "$SEED/Frameworks/libANGLE-shared.dylib" "$ROOT/build/ios-arm64/sysroot/lib/"
for f in vmlinuz-virt initramfs-virt; do cp "$SEED/$f" "$ROOT/guests/phase0/"; done
BIOS="$ROOT/third_party/build/qemu-10.0.12-utm/pc-bios"
bzip2 -c "$SEED/edk2-aarch64-code.fd" > "$BIOS/edk2-aarch64-code.fd.bz2"
if [ -d "$SEED/pc-bios" ]; then cp -R "$SEED/pc-bios/." "$BIOS/"; fi
for resource in android-system java-runtime; do
  test -d "$SEED/$resource" || { echo "Missing official runtime: $resource" >&2; exit 1; }
  mkdir -p "$ROOT/build/$resource"
  cp -R "$SEED/$resource/." "$ROOT/build/$resource/"
done
MOLTEN="$SEED/Frameworks/MoltenVK.framework"
test -f "$MOLTEN/MoltenVK"
xcodebuild -create-xcframework -framework "$MOLTEN" -output "$ROOT/build/ios-arm64/lib/MoltenVK.xcframework"
printf '%s\n' 'Official 2.0 binary dependencies and runtime resources staged.'
