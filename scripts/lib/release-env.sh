# Shared paths and signing defaults for GUI release scripts.
# Source this file; do not execute directly.

: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}"
: "${PROJECT_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
: "${DERIVED_DATA:=$HOME/Developer/DerivedData/TeX2img}"

PRODUCT_NAME="TeX2img"
SCHEME_GUI="TeX2img GUI"
SCHEME_CUI="tex2img CUI"

CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application: Yusuke Terada (86GWZ48925)}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-86GWZ48925}"

ARCHIVE_PATH="${ARCHIVE_PATH:-$DERIVED_DATA/Archives/TeX2img.xcarchive}"
PRODUCTS_RELEASE="$DERIVED_DATA/Build/Products/Release"

APPCAST_DIR="$PROJECT_DIR/../TeX2img_Appcast"
APPCAST_XML="$APPCAST_DIR/TeX2img_Appcast.xml"
DSA_PRIVATE_KEY="$PROJECT_DIR/../設定/証明書/Sparkle/dsa_priv.pem"
OPENSSL="${OPENSSL:-/usr/bin/openssl}"

# Notarization auth (one of):
#   NOTARY_KEYCHAIN_PROFILE  — preferred; see docs/build-and-deploy.md
#   NOTARY_APPLE_ID + NOTARY_PASSWORD + NOTARY_TEAM_ID
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"

app_version_from_plist() {
    local plist="$1"
    /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist"
}

# Xcode の INSTALL_PATH 設定により Products/Applications 以外になることがある。
find_archived_app() {
    local archive="$1"
    local app
    app=$(find "$archive/Products" -name "${PRODUCT_NAME}.app" -maxdepth 6 -type d 2>/dev/null | head -1)
    if [[ -z "$app" ]]; then
        echo "ERROR: ${PRODUCT_NAME}.app not found under $archive/Products" >&2
        return 1
    fi
    echo "$app"
}