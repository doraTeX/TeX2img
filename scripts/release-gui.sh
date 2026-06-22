#!/bin/bash
# Full GUI release: Archive → verify bundle → notarize app → DMG → notarize DMG → Appcast.
#
# Replaces the manual Xcode Organizer flow for distribution outside the Mac App Store.
#
# Prerequisites:
#   Developer ID Application certificate in Keychain
#   Notarization credentials (see docs/build-and-deploy.md)
#   ../TeX2img_Appcast/TeX2img_Appcast.xml
#   ../設定/証明書/Sparkle/dsa_priv.pem
#
# Usage:
#   scripts/release-gui.sh
#   SKIP_DMG_NOTARIZE=1 scripts/release-gui.sh   # app only (not recommended)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

"$SCRIPT_DIR/archive-gui.sh"

ARCHIVED_APP="$(find_archived_app "$ARCHIVE_PATH")"
APP_PATH="$ARCHIVED_APP" "$SCRIPT_DIR/verify-bundle.sh" Release

echo ""
echo "=== Notarizing app ==="
"$SCRIPT_DIR/notarize.sh" "$ARCHIVED_APP"

VERSION="$(app_version_from_plist "$ARCHIVED_APP/Contents/Info.plist")"
DMG="$PRODUCTS_RELEASE/${PRODUCT_NAME}_${VERSION}.dmg"
"$SCRIPT_DIR/make-gui-dmg.sh" "$ARCHIVED_APP" "$DMG"

if [[ "${SKIP_DMG_NOTARIZE:-}" != "1" ]]; then
    echo ""
    echo "=== Notarizing DMG ==="
    "$SCRIPT_DIR/notarize.sh" "$DMG"
else
    echo "SKIP_DMG_NOTARIZE=1 — DMG notarization skipped." >&2
fi

echo ""
"$SCRIPT_DIR/publish-gui.sh" "$DMG"

echo ""
echo "=== Release complete ==="
echo "Archive: $ARCHIVE_PATH"
echo "App:     $ARCHIVED_APP"
echo "DMG:     $DMG"
echo "Appcast: $APPCAST_XML"