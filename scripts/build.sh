#!/bin/bash
# Build TeX2img (GUI) and/or tex2img (CUI).
#
# Usage:
#   scripts/build.sh TeX2img [Debug|Release]   # GUI (+ bundled CUI)
#   scripts/build.sh tex2img [Debug|Release]   # CUI only
#   scripts/build.sh all     [Debug|Release]   # both (see docs for caveats)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"
CONFIGURATION="${2:-}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <TeX2img|tex2img|all> [Debug|Release]" >&2
    exit 1
fi

ARGS=("$TARGET")
[[ -n "$CONFIGURATION" ]] && ARGS+=("$CONFIGURATION")

"$SCRIPT_DIR/safe-build.sh" "${ARGS[@]}"

if [[ "$TARGET" == "TeX2img" || "$TARGET" == "all" ]]; then
    CONFIG="${CONFIGURATION:-Debug}"
    "$SCRIPT_DIR/verify-bundle.sh" "$CONFIG"
fi

DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
CONFIG="${CONFIGURATION:-Debug}"
PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIG"

echo ""
echo "Build products:"
[[ -d "$PRODUCTS/TeX2img.app" ]] && echo "  GUI:  $PRODUCTS/TeX2img.app"
[[ -f "$PRODUCTS/tex2img" ]] && echo "  CUI:  $PRODUCTS/tex2img"
[[ -f "$PRODUCTS/TeX2img.app/Contents/SharedSupport/bin/tex2img" ]] && \
    echo "  CUI in bundle: $PRODUCTS/TeX2img.app/Contents/SharedSupport/bin/tex2img"