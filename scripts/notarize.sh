#!/bin/bash
# Submit a .app or .dmg to Apple's Notarization Service and staple the ticket.
#
# Usage:
#   scripts/notarize.sh /path/to/TeX2img.app
#   scripts/notarize.sh /path/to/TeX2img_2.4.3.dmg
#
# Authentication (pick one):
#   NOTARY_KEYCHAIN_PROFILE=tex2img-notary
#   NOTARY_APPLE_ID=... NOTARY_PASSWORD=... NOTARY_TEAM_ID=86GWZ48925
#
# Store a keychain profile once:
#   xcrun notarytool store-credentials tex2img-notary \
#     --apple-id YOUR_APPLE_ID --team-id 86GWZ48925
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

usage() {
    echo "Usage: $0 <path-to-.app-or-.dmg>" >&2
    exit 1
}

TARGET="${1:-}"
[[ -n "$TARGET" ]] || usage
[[ -e "$TARGET" ]] || { echo "ERROR: Not found: $TARGET" >&2; exit 1; }

notary_submit() {
    local file="$1"
    if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
        xcrun notarytool submit "$file" \
            --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
            --wait
    elif [[ -n "${NOTARY_APPLE_ID:-}" && -n "${NOTARY_PASSWORD:-}" && -n "${NOTARY_TEAM_ID:-}" ]]; then
        xcrun notarytool submit "$file" \
            --apple-id "$NOTARY_APPLE_ID" \
            --password "$NOTARY_PASSWORD" \
            --team-id "$NOTARY_TEAM_ID" \
            --wait
    else
        echo "ERROR: Notarization credentials not configured." >&2
        echo "Set NOTARY_KEYCHAIN_PROFILE, or NOTARY_APPLE_ID + NOTARY_PASSWORD + NOTARY_TEAM_ID." >&2
        echo "See docs/build-and-deploy.md" >&2
        exit 1
    fi
}

cleanup_zip=""
trap '[[ -n "$cleanup_zip" && -f "$cleanup_zip" ]] && rm -f "$cleanup_zip"' EXIT

SUBMIT_FILE="$TARGET"
STAPLE_TARGET="$TARGET"

if [[ -d "$TARGET" && "$TARGET" == *.app ]]; then
    cleanup_zip="$(mktemp -t tex2img-notarize.XXXXXX.zip)"
    echo "=== Zipping app for notarization ==="
    ditto -c -k --keepParent "$TARGET" "$cleanup_zip"
    SUBMIT_FILE="$cleanup_zip"
fi

echo "=== Submitting to Notarization Service ==="
echo "    $TARGET"
notary_submit "$SUBMIT_FILE"

echo "=== Stapling notarization ticket ==="
xcrun stapler staple "$STAPLE_TARGET"
xcrun stapler validate "$STAPLE_TARGET"

echo ""
echo "Notarized and stapled: $STAPLE_TARGET"