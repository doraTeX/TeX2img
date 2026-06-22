#!/bin/bash
# Build Release GUI (with bundled CUI) and run the Sparkle deploy script.
#
# Prerequisites (outside this repo):
#   ../TeX2imgDmg/Disk Image.dmg     — DMG template with TeX2img.app layout
#   ../TeX2img_Appcast/TeX2img_Appcast.xml
#   ../設定/証明書/Sparkle/dsa_priv.pem
#   Developer ID Application certificate in Keychain
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"

DMG_TEMPLATE="$PROJECT_DIR/../TeX2imgDmg/Disk Image.dmg"
if [[ ! -f "$DMG_TEMPLATE" ]]; then
    echo "ERROR: DMG template not found: $DMG_TEMPLATE" >&2
    echo "Prepare TeX2imgDmg/Disk Image.dmg (sibling of the repo) before deploying." >&2
    exit 1
fi

"$SCRIPT_DIR/build.sh" TeX2img Release

if [[ ! -f "$PRODUCTS/deploy.sh" ]]; then
    echo "ERROR: deploy.sh was not generated in $PRODUCTS" >&2
    exit 1
fi

(
    cd "$PRODUCTS"
    ./deploy.sh
)

DMG="$(ls -1 "$PRODUCTS"/TeX2img_*.dmg 2>/dev/null | tail -1)"
if [[ -n "$DMG" && -f "$DMG" ]]; then
    echo ""
    echo "Created: $DMG"
    echo "Updated: $PROJECT_DIR/../TeX2img_Appcast/TeX2img_Appcast.xml"
else
    echo "WARNING: DMG may not have been created. Check deploy.sh output." >&2
fi