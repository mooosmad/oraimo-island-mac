#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Oraimo Island.app"
codesign --verify --deep --strict "$APP"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ARCHIVE="$ROOT/dist/Oraimo-Island-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
(cd "$ROOT/dist" && shasum -a 256 "$(basename "$ARCHIVE")" >> SHA256SUMS.txt)
echo "Archive de mise à jour : $ARCHIVE"
