#!/bin/bash
# Safe xcodebuild wrapper: local DerivedData, single job, sequential schemes.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
CONFIGURATION="${CONFIGURATION:-Debug}"
JOBS="${JOBS:-1}"

usage() {
    echo "Usage: $0 <TeX2img|tex2img|all> [Debug|Release]" >&2
    exit 1
}

TARGET="${1:-}"
[[ -n "$TARGET" ]] || usage
[[ $# -ge 2 ]] && CONFIGURATION="$2"

mkdir -p "$DERIVED_DATA"

resolve_packages() {
    xcodebuild -resolvePackageDependencies \
        -project "$PROJECT_DIR/TeX2img.xcodeproj" \
        -scheme "tex2img CUI" \
        -derivedDataPath "$DERIVED_DATA"
}

build_scheme() {
    local scheme="$1"
    echo "=== Building scheme '$scheme' ($CONFIGURATION, -jobs $JOBS) ==="
    xcodebuild \
        -project "$PROJECT_DIR/TeX2img.xcodeproj" \
        -scheme "$scheme" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA" \
        -jobs "$JOBS" \
        build
}

case "$TARGET" in
    tex2img)
        resolve_packages
        build_scheme "tex2img CUI"
        ;;
    TeX2img)
        resolve_packages
        build_scheme "TeX2img GUI"
        ;;
    all)
        resolve_packages
        build_scheme "tex2img CUI"
        build_scheme "TeX2img GUI"
        ;;
    *) usage ;;
esac

echo "=== Done: $TARGET ($CONFIGURATION) ==="