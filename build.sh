#!/usr/bin/env bash
# Builds NET Study.app for Apple silicon.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="NET Study"
BIN_NAME="NETStudy"
BUILD="$ROOT/build"
APP="$BUILD/$APP_NAME.app"

# SwiftUI in the macOS 27 SDK requires Xcode's macro plugin, which isn't part of
# the Command Line Tools. The 26.5 SDK still ships SwiftUI as plain property
# wrappers, so we compile against it and deploy to macOS 14+.
SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [ ! -d "$SDK" ]; then
    SDK="$(xcrun --show-sdk-path)"
fi

echo "→ compiling against $SDK"
mkdir -p "$BUILD"
swiftc -O -parse-as-library \
    -sdk "$SDK" \
    -target arm64-apple-macos14.0 \
    Sources/*.swift \
    -o "$BUILD/$BIN_NAME"

echo "→ assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"
cp Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if [ ! -f "$BUILD/AppIcon.icns" ]; then
    echo "→ generating icon"
    mkdir -p "$BUILD/icon"
    swiftc -O Icon/makeicon.swift -o "$BUILD/makeicon" 2>/dev/null
    "$BUILD/makeicon" "$BUILD/icon/icon-1024.png" >/dev/null

    ICONSET="$BUILD/AppIcon.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    for s in 16 32 128 256 512; do
        sips -z $s $s "$BUILD/icon/icon-1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
        d=$((s * 2))
        sips -z $d $d "$BUILD/icon/icon-1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
    done
    cp "$BUILD/icon/icon-1024.png" "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$BUILD/AppIcon.icns"
fi

cp "$BUILD/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "→ signing (ad-hoc)"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ built $APP"
du -sh "$APP"
