#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ClipSaver"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cp "$BUILD_DIR/ClipSaverApp" "$MACOS_DIR/$APP_NAME"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/$APP_NAME"

codesign --force --sign - "$APP_DIR"

echo "Built $APP_DIR"
