#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/.build"
DIST_DIR="$ROOT/dist"
APP="$DIST_DIR/Oraimo Island.app"
CACHE="${ORAIMO_MODULE_CACHE:-$BUILD_DIR/module-cache}"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
MIN_OS=14.0
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$CACHE"
for ARCH in arm64 x86_64; do
  echo "Compilation $ARCH (macOS $MIN_OS+)"
  xcrun swiftc -module-cache-path "$CACHE" -sdk "$SDK" -target "$ARCH-apple-macosx$MIN_OS" \
    -swift-version 5 -O "$ROOT/Sources/OraimoProduct.swift" "$ROOT/Sources/BatteryData.swift" "$ROOT/Sources/main.swift" \
    -framework AppKit -framework SwiftUI -framework IOBluetooth -framework CoreBluetooth -framework CoreAudio \
    -o "$BUILD_DIR/OraimoIsland-$ARCH"
done
STAGING="$(mktemp -d "$BUILD_DIR/app.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/Contents/MacOS" "$STAGING/Contents/Resources"
xcrun lipo -create "$BUILD_DIR/OraimoIsland-arm64" "$BUILD_DIR/OraimoIsland-x86_64" -output "$STAGING/Contents/MacOS/OraimoIsland"
cp "$ROOT/Resources/Info.plist" "$STAGING/Contents/Info.plist"
cp "$ROOT/Resources/"*.png "$ROOT/Resources/"*.icns "$STAGING/Contents/Resources/"
chmod -R a+rX "$STAGING"
if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$STAGING"
else
  codesign --force --sign - "$STAGING"
fi
codesign --verify --deep --strict "$STAGING"
if [[ -d "$APP" ]]; then rm -rf "$APP"; fi
mv "$STAGING" "$APP"
echo "Application : $APP"
xcrun lipo -archs "$APP/Contents/MacOS/OraimoIsland"
