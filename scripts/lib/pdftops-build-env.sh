# Poppler pdftops universal bundle build settings.
# Source this file; do not execute directly.

: "${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}"
: "${PROJECT_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"

POPPLER_VERSION="${POPPLER_VERSION:-20.09.0}"
POPPLER_TARBALL="poppler-${POPPLER_VERSION}.tar.xz"
POPPLER_URL="https://poppler.freedesktop.org/${POPPLER_TARBALL}"

# arm64 スライスの最低 macOS 版。
# 未指定でビルドするとホスト OS（例: 15.x / 26.x）が入り、要件が厳しすぎる。
ARM64_MIN_OS="${ARM64_MIN_OS:-11.0}"

X86_SRC="${X86_SRC:-$PROJECT_DIR/Resources/pdftops}"
WORK_ROOT="${WORK_ROOT:-$PROJECT_DIR/build/pdftops-build}"
ARM64_STAGE="${ARM64_STAGE:-$WORK_ROOT/arm64-stage}"
UNIVERSAL_OUT="${UNIVERSAL_OUT:-$WORK_ROOT/universal}"
POPPLER_SRC="${POPPLER_SRC:-$WORK_ROOT/src/poppler-${POPPLER_VERSION}}"
POPPLER_BUILD="${POPPLER_BUILD:-$WORK_ROOT/build-arm64}"
POPPLER_PREFIX="${POPPLER_PREFIX:-$WORK_ROOT/install-arm64}"

PDFTOPS_RPATH="@executable_path/pdftops-lib"

apply_arm64_deployment_target() {
    if [[ -d /opt/local/lib/pkgconfig ]]; then
        export PKG_CONFIG_PATH="/opt/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    fi
    export MACOSX_DEPLOYMENT_TARGET="$ARM64_MIN_OS"
    export CMAKE_OSX_DEPLOYMENT_TARGET="$ARM64_MIN_OS"
    export CMAKE_OSX_ARCHITECTURES=arm64
    local mm="-mmacosx-version-min=${ARM64_MIN_OS}"
    export CFLAGS="${mm} ${CFLAGS:-}"
    export CXXFLAGS="${mm} ${CXXFLAGS:-}"
    export LDFLAGS="${mm} ${LDFLAGS:-}"
    export CPPFLAGS="${mm} ${CPPFLAGS:-}"
    export PKG_CONFIG_PATH="${POPPLER_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
}