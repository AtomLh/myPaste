#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
swift build -c "$CONFIG"

if [ "$CONFIG" = "release" ]; then
    BIN=".build/release/myPaste"
else
    BIN=".build/debug/myPaste"
fi
APP="build/myPaste.app"
ICONSET="build/myPaste.iconset"
ICNS="build/AppIcon.icns"

# Generate icon
echo "Rendering app icon…"
swift scripts/render_icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"

# Build .app bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/myPaste"
cp scripts/Info.plist.template "$APP/Contents/Info.plist"
cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"

# Force Finder to refresh icon cache for this app
touch "$APP"

echo "Built: $APP"
