#!/bin/bash
# Verify that the GUI app bundle contains the CUI tex2img binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
CONFIGURATION="${1:-Debug}"

APP="${APP_PATH:-$DERIVED_DATA/Build/Products/$CONFIGURATION/TeX2img.app}"
CUI_IN_BUNDLE="$APP/Contents/SharedSupport/bin/tex2img"
STANDALONE="$DERIVED_DATA/Build/Products/$CONFIGURATION/tex2img"

if [[ ! -d "$APP" ]]; then
    echo "ERROR: TeX2img.app not found: $APP" >&2
    echo "Build first: $SCRIPT_DIR/build.sh TeX2img $CONFIGURATION" >&2
    exit 1
fi

# A valid .app bundle root must contain only Contents/. Stray files or symlinks
# (often from manual ln -sf during testing) break CodeSign with:
#   "unsealed contents present in the bundle root"
for item in "$APP"/*; do
    [[ "$(basename "$item")" == "Contents" ]] && continue
    echo "ERROR: Unexpected item in app bundle root (breaks CodeSign): $item" >&2
    if [[ -L "$item" ]]; then
        echo "  symlink target: $(readlink "$item")" >&2
    fi
    echo "Remove it, then rebuild (Product > Clean Build Folder in Xcode also works)." >&2
    exit 1
done

if [[ ! -f "$CUI_IN_BUNDLE" ]]; then
    echo "ERROR: Bundled tex2img missing: $CUI_IN_BUNDLE" >&2
    echo "Expected path: Contents/SharedSupport/bin/tex2img" >&2
    exit 1
fi

if [[ ! -x "$CUI_IN_BUNDLE" ]]; then
    echo "ERROR: Bundled tex2img is not executable: $CUI_IN_BUNDLE" >&2
    exit 1
fi

BUNDLE_VERSION="$("$CUI_IN_BUNDLE" --version 2>&1 | head -1 || true)"

if [[ -f "$STANDALONE" ]]; then
    STANDALONE_VERSION="$("$STANDALONE" --version 2>&1 | head -1 || true)"
    if [[ "$BUNDLE_VERSION" != "$STANDALONE_VERSION" ]]; then
        echo "ERROR: Version mismatch between bundled and standalone tex2img." >&2
        echo "  bundle:     $BUNDLE_VERSION" >&2
        echo "  standalone: $STANDALONE_VERSION" >&2
        echo "Rebuild with: $SCRIPT_DIR/build.sh TeX2img $CONFIGURATION" >&2
        exit 1
    fi
    BUNDLE_SIZE=$(stat -f%z "$CUI_IN_BUNDLE")
    STANDALONE_SIZE=$(stat -f%z "$STANDALONE")
    if [[ "$BUNDLE_SIZE" != "$STANDALONE_SIZE" ]]; then
        echo "WARNING: File size differs (codesign may differ): bundle=$BUNDLE_SIZE standalone=$STANDALONE_SIZE" >&2
    fi
fi

echo "OK: $CUI_IN_BUNDLE"
echo "    $BUNDLE_VERSION"