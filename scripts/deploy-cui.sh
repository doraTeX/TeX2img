#!/bin/bash
# Build Release CUI and create the distribution zip (tex2imgcMac{version}.zip).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"

"$SCRIPT_DIR/build.sh" tex2img Release

VERSION=$(grep 'let tex2imgVersion' "$PROJECT_DIR/Sources/CLI/mainc.swift" \
    | sed 's/.*= "\(.*\)"/\1/')
ZIP="$PRODUCTS/tex2imgcMac${VERSION}.zip"

(
    cd "$PRODUCTS"
    rm -f "$ZIP"
    zip "$ZIP" tex2img
)

echo ""
echo "Created: $ZIP"