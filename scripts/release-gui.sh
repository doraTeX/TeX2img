#!/bin/bash
# GUI release: Archive → verify bundle → notarize app → DMG → notarize DMG → Appcast.
#
# Prerequisites:
#   Developer ID Application certificate in Keychain
#   Notarization credentials (see docs/build-and-deploy.md)
#   ../TeX2img_Appcast/TeX2img_Appcast.xml
#   ../設定/証明書/Sparkle/dsa_priv.pem
#
# Usage:
#   scripts/release-gui.sh
#   SKIP_DMG_NOTARIZE=1 scripts/release-gui.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/release-env.sh
source "$SCRIPT_DIR/lib/release-env.sh"

JOBS="${JOBS:-1}"

archive_gui() {
    echo "=== Resolving package dependencies ==="
    xcodebuild -resolvePackageDependencies \
        -project "$PROJECT_DIR/TeX2img.xcodeproj" \
        -scheme "$SCHEME_CUI" \
        -derivedDataPath "$DERIVED_DATA"

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

    local archived_app
    archived_app="$(find_archived_app "$ARCHIVE_PATH")"
    echo ""
    echo "Archive created: $ARCHIVE_PATH"
    echo "App:             $archived_app"
    echo ""
    echo "Verify signing:"
    codesign -dv --verbose=4 "$archived_app" 2>&1 | grep -E 'Authority|TeamIdentifier|Runtime Version' || true
}

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

notarize_target() {
    local target="$1"
    [[ -e "$target" ]] || { echo "ERROR: Not found: $target" >&2; exit 1; }

    local submit_file="$target"
    local staple_target="$target"
    local cleanup_zip=""

    if [[ -d "$target" && "$target" == *.app ]]; then
        cleanup_zip="$(mktemp -t tex2img-notarize.XXXXXX.zip)"
        echo "=== Zipping app for notarization ==="
        ditto -c -k --keepParent "$target" "$cleanup_zip"
        submit_file="$cleanup_zip"
    fi

    echo "=== Submitting to Notarization Service ==="
    echo "    $target"
    notary_submit "$submit_file"
    [[ -n "$cleanup_zip" && -f "$cleanup_zip" ]] && rm -f "$cleanup_zip"

    echo "=== Stapling notarization ticket ==="
    xcrun stapler staple "$staple_target"
    xcrun stapler validate "$staple_target"
    echo ""
    echo "Notarized and stapled: $staple_target"
}

make_gui_dmg() {
    local app="$1"
    local dmg="$2"
    [[ -d "$app" ]] || { echo "ERROR: App not found: $app" >&2; exit 1; }

    mkdir -p "$(dirname "$dmg")"
    [[ -f "$dmg" ]] && rm -f "$dmg"

    echo "=== Creating DMG ==="
    echo "    source: $app"
    echo "    output: $dmg"

    hdiutil create \
        -ov \
        -srcfolder "$app" \
        -fs HFS+ \
        -format UDZO \
        -imagekey zlib-level=9 \
        -volname "$PRODUCT_NAME" \
        "$dmg"

    echo "=== Signing DMG ==="
    codesign --force --sign "$CODE_SIGN_IDENTITY" "$dmg"
    echo ""
    echo "Created: $dmg"
}

publish_gui_appcast() {
    local dmg="$1"
    [[ -f "$dmg" ]] || { echo "ERROR: DMG not found: $dmg" >&2; exit 1; }
    [[ -f "$APPCAST_XML" ]] || { echo "ERROR: Appcast not found: $APPCAST_XML" >&2; exit 1; }
    [[ -f "$DSA_PRIVATE_KEY" ]] || { echo "ERROR: Sparkle DSA private key not found: $DSA_PRIVATE_KEY" >&2; exit 1; }

    local basename version signature length tmp
    basename="$(basename "$dmg")"
    version="${basename#${PRODUCT_NAME}_}"
    version="${version%.dmg}"

    echo "=== Updating Sparkle appcast ==="
    echo "    DMG:     $dmg"
    echo "    version: $version"

    signature=$("$OPENSSL" dgst -sha1 -binary < "$dmg" \
        | "$OPENSSL" dgst -dss1 -sign "$DSA_PRIVATE_KEY" \
        | "$OPENSSL" enc -base64 | tr -d '\n')
    length=$(stat -f%z "$dmg")

    tmp="${APPCAST_XML%.xml}2.xml"
    sed \
        -e "s|dsaSignature=\".*\"|dsaSignature=\"$signature\"|" \
        -e "s|length=\".*\"|length=\"$length\"|" \
        -e "s|${PRODUCT_NAME}_.*\\.dmg|${basename}|" \
        -e "s|sparkle:version=\".*\"|sparkle:version=\"$version\"|" \
        "$APPCAST_XML" > "$tmp"
    mv "$tmp" "$APPCAST_XML"

    echo ""
    echo "Updated: $APPCAST_XML"
}

archive_gui

ARCHIVED_APP="$(find_archived_app "$ARCHIVE_PATH")"
APP_PATH="$ARCHIVED_APP" "$SCRIPT_DIR/verify-bundle.sh" Release

echo ""
echo "=== Notarizing app ==="
notarize_target "$ARCHIVED_APP"

VERSION="$(app_version_from_plist "$ARCHIVED_APP/Contents/Info.plist")"
DMG="$PRODUCTS_RELEASE/${PRODUCT_NAME}_${VERSION}.dmg"
make_gui_dmg "$ARCHIVED_APP" "$DMG"

if [[ "${SKIP_DMG_NOTARIZE:-}" != "1" ]]; then
    echo ""
    echo "=== Notarizing DMG ==="
    notarize_target "$DMG"
else
    echo "SKIP_DMG_NOTARIZE=1 — DMG notarization skipped." >&2
fi

echo ""
publish_gui_appcast "$DMG"

echo ""
echo "=== Release complete ==="
echo "Archive: $ARCHIVE_PATH"
echo "App:     $ARCHIVED_APP"
echo "DMG:     $DMG"
echo "Appcast: $APPCAST_XML"