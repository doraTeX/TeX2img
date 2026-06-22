#!/bin/bash
# Sign bundled helper binaries with Hardened Runtime for notarization.
#
# pdftops and its dylibs ship adhoc-signed in Resources/. Re-sign them here
# after they are copied into the app bundle (Xcode Run Script phase).
#
# Usage:
#   scripts/sign-bundled-tools.sh [path/to/TeX2img.app]
#
# Environment (set automatically by Xcode):
#   BUILT_PRODUCTS_DIR, PRODUCT_NAME, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM
set -euo pipefail

APP="${1:-${BUILT_PRODUCTS_DIR:?}/${PRODUCT_NAME:?}.app}"
IDENTITY="${CODE_SIGN_IDENTITY:-}"
STAMP="${DERIVED_FILE_DIR:+$DERIVED_FILE_DIR/sign-bundled-tools.stamp}"

write_stamp() {
    [[ -n "$STAMP" ]] || return 0
    mkdir -p "$(dirname "$STAMP")"
    touch "$STAMP"
}

if [[ -z "$IDENTITY" || "$IDENTITY" == "-" ]]; then
    echo "note: CODE_SIGN_IDENTITY not set; skipping bundled tool signing"
    write_stamp
    exit 0
fi

sign_macho() {
    local file="$1"
    echo "Signing $(basename "$file")"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$file"
}

PDFTOPS_DIR="$APP/Contents/Resources/pdftops"
if [[ ! -d "$PDFTOPS_DIR" ]]; then
    echo "note: pdftops directory not found; skipping"
    write_stamp
    exit 0
fi

if [[ -d "$PDFTOPS_DIR/pdftops-lib" ]]; then
    for dylib in "$PDFTOPS_DIR/pdftops-lib"/*.dylib; do
        [[ -f "$dylib" ]] || continue
        sign_macho "$dylib"
    done
fi

if [[ -f "$PDFTOPS_DIR/pdftops" ]]; then
    sign_macho "$PDFTOPS_DIR/pdftops"
fi

write_stamp
echo "Bundled tool signing complete."