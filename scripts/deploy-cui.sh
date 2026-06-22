#!/bin/bash
# Build Release CUI and create the distribution zip (tex2imgcMac{version}.zip).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"

"$SCRIPT_DIR/build.sh" tex2img Release

if [[ ! -f "$PRODUCTS/deployc.sh" ]]; then
    echo "ERROR: deployc.sh was not generated in $PRODUCTS" >&2
    exit 1
fi

(
    cd "$PRODUCTS"
    ./deployc.sh
)

ZIP="$(ls -1 "$PRODUCTS"/tex2imgcMac*.zip 2>/dev/null | tail -1)"
if [[ -n "$ZIP" && -f "$ZIP" ]]; then
    echo ""
    echo "Created: $ZIP"
else
    echo "ERROR: zip file not found in $PRODUCTS" >&2
    exit 1
fi