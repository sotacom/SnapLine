#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/scripts/build_app.sh"

APP_PATH="$ROOT_DIR/build/SnapLine.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_NAME="SnapLine-${VERSION}-macos-arm64.dmg"
ZIP_NAME="SnapLine-${VERSION}-macos-arm64.zip"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME" "$DIST_DIR/$ZIP_NAME" "$DIST_DIR/SHA256SUMS.txt"

echo "==> Creating ZIP archive ($ZIP_NAME)..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DIST_DIR/$ZIP_NAME"

echo "==> Creating compressed DMG ($DMG_NAME)..."
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

cp -R "$APP_PATH" "$STAGE_DIR/SnapLine.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "SnapLine ${VERSION}" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$DMG_NAME"

echo "==> Generating SHA256SUMS.txt..."
(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_NAME" "$ZIP_NAME" > SHA256SUMS.txt
)

ls -lh "$DIST_DIR"
cat "$DIST_DIR/SHA256SUMS.txt"
