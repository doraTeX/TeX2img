#!/bin/bash
# Create a compressed DMG from a TeX2img.app bundle.
#
# Usage:
#   scripts/make-gui-dmg.sh /path/to/TeX2img.app [/path/to/output.dmg]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

APP="${1:-}"
if [[ -z "$APP" ]]; then
    echo "Usage: $0 <TeX2img.app> [output.dmg]" >&2
    exit 1
fi
[[ -d "$APP" ]] || { echo "ERROR: App not found: $APP" >&2; exit 1; }

VERSION="$(app_version_from_plist "$APP/Contents/Info.plist")"
DMG="${2:-$PRODUCTS_RELEASE/${PRODUCT_NAME}_${VERSION}.dmg}"

mkdir -p "$(dirname "$DMG")"
[[ -f "$DMG" ]] && rm -f "$DMG"

echo "=== Creating DMG ==="
echo "    source: $APP"
echo "    output: $DMG"

hdiutil create \
    -ov \
    -srcfolder "$APP" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -volname "$PRODUCT_NAME" \
    "$DMG"

echo "=== Signing DMG ==="
codesign --force --sign "$CODE_SIGN_IDENTITY" "$DMG"

echo ""
echo "Created: $DMG"