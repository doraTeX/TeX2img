#!/bin/bash
# Create a Release .xcarchive for TeX2img GUI (Developer ID signed).
#
# Equivalent to Xcode: Product → Archive with scheme "TeX2img GUI".
#
# Usage:
#   scripts/archive-gui.sh
#   ARCHIVE_PATH=/path/to/TeX2img.xcarchive scripts/archive-gui.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

JOBS="${JOBS:-1}"

echo "=== Resolving package dependencies ==="
xcodebuild -resolvePackageDependencies \
    -project "$PROJECT_DIR/TeX2img.xcodeproj" \
    -scheme "$SCHEME_CUI" \
    -derivedDataPath "$DERIVED_DATA"

# 共有 Swift ソースのリンク順問題を避けるため、Archive の前に CUI を単独ビルドする。
echo "=== Pre-building $SCHEME_CUI (Release) ==="
xcodebuild \
    -project "$PROJECT_DIR/TeX2img.xcodeproj" \
    -scheme "$SCHEME_CUI" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    -jobs "$JOBS" \
    build

mkdir -p "$(dirname "$ARCHIVE_PATH")"
if [[ -d "$ARCHIVE_PATH" ]]; then
    echo "Removing existing archive: $ARCHIVE_PATH"
    rm -rf "$ARCHIVE_PATH"
fi

echo "=== Archiving $SCHEME_GUI (Release) ==="
xcodebuild archive \
    -project "$PROJECT_DIR/TeX2img.xcodeproj" \
    -scheme "$SCHEME_GUI" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    -archivePath "$ARCHIVE_PATH" \
    -jobs "$JOBS"

ARCHIVED_APP="$(find_archived_app "$ARCHIVE_PATH")"

echo ""
echo "Archive created: $ARCHIVE_PATH"
echo "App:             $ARCHIVED_APP"
echo ""
echo "Verify signing:"
codesign -dv --verbose=4 "$ARCHIVED_APP" 2>&1 | grep -E 'Authority|TeamIdentifier|Runtime Version' || true