#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${ORAIMO_MODULE_CACHE:-$ROOT/.build/module-cache}"
mkdir -p "$ROOT/.build" "$CACHE"
xcrun swiftc -module-cache-path "$CACHE" "$ROOT/Sources/OraimoProduct.swift" "$ROOT/Sources/BatteryData.swift" "$ROOT/Sources/DeviceState.swift" "$ROOT/Tests/main.swift" -o "$ROOT/.build/battery-tests"
"$ROOT/.build/battery-tests"
