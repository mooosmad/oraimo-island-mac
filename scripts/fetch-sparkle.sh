#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=2.10.1
SHA256=1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27
DEST="$ROOT/.build/sparkle/$VERSION"
if [[ ! -f "$DEST/.verified-$SHA256" ]]; then
  mkdir -p "$ROOT/.build/sparkle"
  TEMP="$(mktemp -d "$ROOT/.build/sparkle/download.XXXXXX")"
  trap 'rm -rf "$TEMP"' EXIT
  curl --fail --location --retry 3 --connect-timeout 20 --max-time 600 \
    "https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz" -o "$TEMP/sparkle.tar.xz"
  printf '%s  %s\n' "$SHA256" "$TEMP/sparkle.tar.xz" | shasum -a 256 -c - >&2
  mkdir "$TEMP/package"
  tar -xf "$TEMP/sparkle.tar.xz" -C "$TEMP/package"
  touch "$TEMP/package/.verified-$SHA256"
  rm -rf "$DEST"
  mv "$TEMP/package" "$DEST"
fi
printf '%s\n' "$DEST"
