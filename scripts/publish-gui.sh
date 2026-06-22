#!/bin/bash
# Sign Sparkle appcast entry for a finished DMG (DSA) and update TeX2img_Appcast.xml.
#
# Run after the DMG is signed, notarized, and stapled — file size must be final.
#
# Usage:
#   scripts/publish-gui.sh /path/to/TeX2img_2.4.3.dmg
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

DMG="${1:-}"
if [[ -z "$DMG" ]]; then
    echo "Usage: $0 <TeX2img_VERSION.dmg>" >&2
    exit 1
fi
[[ -f "$DMG" ]] || { echo "ERROR: DMG not found: $DMG" >&2; exit 1; }

if [[ ! -f "$APPCAST_XML" ]]; then
    echo "ERROR: Appcast not found: $APPCAST_XML" >&2
    exit 1
fi
if [[ ! -f "$DSA_PRIVATE_KEY" ]]; then
    echo "ERROR: Sparkle DSA private key not found: $DSA_PRIVATE_KEY" >&2
    exit 1
fi

BASENAME="$(basename "$DMG")"
VERSION="${BASENAME#${PRODUCT_NAME}_}"
VERSION="${VERSION%.dmg}"

echo "=== Updating Sparkle appcast ==="
echo "    DMG:     $DMG"
echo "    version: $VERSION"

SIGNATURE=$("$OPENSSL" dgst -sha1 -binary < "$DMG" \
    | "$OPENSSL" dgst -dss1 -sign "$DSA_PRIVATE_KEY" \
    | "$OPENSSL" enc -base64 | tr -d '\n')
LENGTH=$(stat -f%z "$DMG")

TMP="${APPCAST_XML%.xml}2.xml"
sed \
    -e "s|dsaSignature=\".*\"|dsaSignature=\"$SIGNATURE\"|" \
    -e "s|length=\".*\"|length=\"$LENGTH\"|" \
    -e "s|${PRODUCT_NAME}_.*\\.dmg|${BASENAME}|" \
    -e "s|sparkle:version=\".*\"|sparkle:version=\"$VERSION\"|" \
    "$APPCAST_XML" > "$TMP"
mv "$TMP" "$APPCAST_XML"

echo ""
echo "Updated: $APPCAST_XML"