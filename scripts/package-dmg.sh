#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Oraimo Island.app"
DMG="$ROOT/dist/Oraimo-Island-macOS-universal.dmg"
[[ -d "$APP" ]] || { echo "Lance ./build.sh avant de créer le DMG." >&2; exit 1; }
codesign --verify --deep --strict "$APP"
STAGING="$(mktemp -d "$ROOT/.build/dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/Oraimo Island.app"
ln -s /Applications "$STAGING/Applications"
cp "$ROOT/docs/INSTALLER.txt" "$STAGING/Installer.txt"
hdiutil create -ov -volname 'Oraimo Island' -srcfolder "$STAGING" -format UDZO "$DMG"
hdiutil verify "$DMG"
(cd "$ROOT/dist" && shasum -a 256 Oraimo-Island-macOS-universal.dmg > SHA256SUMS.txt)
echo "DMG : $DMG"
