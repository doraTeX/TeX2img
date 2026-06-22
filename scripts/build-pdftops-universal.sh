#!/bin/bash
# Build arm64 Poppler pdftops bundle and merge with existing x86_64 tree via lipo.
#
# arm64 スライスの最低 macOS 版は ARM64_MIN_OS (既定 11.0)。
# MACOSX_DEPLOYMENT_TARGET を指定しないとホスト OS が入り、動作要件が厳しすぎる。
#
# Usage:
#   scripts/build-pdftops-universal.sh fetch          # Poppler ソース取得
#   scripts/build-pdftops-universal.sh arm64          # arm64 ステージをビルド
#   scripts/build-pdftops-universal.sh lipo           # universal ツリー生成
#   scripts/build-pdftops-universal.sh verify         # universal + min OS 検証
#   scripts/build-pdftops-universal.sh install        # Resources/pdftops へ反映
#   scripts/build-pdftops-universal.sh all              # 上記一括（install 除く）
#
# 既に arm64 ステージがある場合:
#   ARM64_STAGE=/path scripts/build-pdftops-universal.sh lipo
#
# Prerequisites (arm64 ビルド):
#   cmake, pkg-config, dylibbundler
#   Poppler 依存 (Homebrew 等): freetype fontconfig jpeg libpng openjpeg libtiff nss curl
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/pdftops-build-env.sh
source "$SCRIPT_DIR/lib/pdftops-build-env.sh"

usage() {
    sed -n '3,16p' "$0" | tr -d '#'
    exit "${1:-0}"
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: required command not found: $cmd" >&2
        exit 1
    }
}

is_macho() {
    file -b "$1" 2>/dev/null | grep -q Mach-O
}

macho_files_under() {
    local root="$1"
    find "$root" -type f 2>/dev/null | while read -r f; do
        is_macho "$f" && echo "$f"
    done
}

fetch_poppler() {
    mkdir -p "$(dirname "$POPPLER_SRC")"
    local archive="$WORK_ROOT/$POPPLER_TARBALL"
    mkdir -p "$WORK_ROOT"

    if [[ -d "$POPPLER_SRC" ]]; then
        echo "Poppler source already present: $POPPLER_SRC"
        return
    fi

    echo "=== Downloading Poppler $POPPLER_VERSION ==="
    if [[ ! -f "$archive" ]]; then
        curl -fL "$POPPLER_URL" -o "$archive"
    fi
    echo "=== Extracting ==="
    tar -xJf "$archive" -C "$(dirname "$POPPLER_SRC")"
}

check_build_prereqs() {
    require_cmd cmake
    require_cmd pkg-config
    require_cmd dylibbundler
    require_cmd lipo
    require_cmd install_name_tool
    require_cmd vtool
    for lib in freetype2 fontconfig libjpeg libpng-16 openjpeg libtiff-4 libcurl nss; do
        pkg-config --exists "$lib" 2>/dev/null || {
            echo "WARNING: pkg-config module missing: $lib" >&2
            echo "         Install Poppler dependencies (e.g. brew install freetype fontconfig jpeg libpng openjpeg libtiff nss curl)" >&2
        }
    done
}

set_arm64_minos_metadata() {
    local file="$1"
    lipo -info "$file" 2>&1 | grep -q arm64 || return 0

    local tmp="$file.vtool.tmp"
    vtool -arch arm64 \
        -set-build-version macos "$ARM64_MIN_OS" "$ARM64_MIN_OS" \
        -set-version-min macos "$ARM64_MIN_OS" "$ARM64_MIN_OS" \
        -output "$tmp" "$file"
    mv "$tmp" "$file"
}

stage_arm64_bundle() {
    local pdftops_bin="$POPPLER_PREFIX/bin/pdftops"
    rm -rf "$ARM64_STAGE"
    mkdir -p "$ARM64_STAGE/pdftops-lib"

    cp "$pdftops_bin" "$ARM64_STAGE/pdftops"
    chmod +x "$ARM64_STAGE/pdftops"

    echo "=== Bundling arm64 dylibs (dylibbundler) ==="
    dylibbundler -of -b \
        -x "$ARM64_STAGE/pdftops" \
        -d "$ARM64_STAGE/pdftops-lib" \
        -p "${PDFTOPS_RPATH}/"

    # 既存 x86_64 ツリーとファイル名を揃える（libpoppler.102.dylib 等）
    echo "=== Aligning dylib names with x86_64 tree ==="
    local x86_lib="$X86_SRC/pdftops-lib"
    local arm_lib="$ARM64_STAGE/pdftops-lib"
    shopt -s nullglob
    for x86_dylib in "$x86_lib"/*.dylib; do
        local base
        base="$(basename "$x86_dylib")"
        if [[ -f "$arm_lib/$base" ]]; then
            continue
        fi
        # 最長一致: libpoppler*.dylib 等
        local stem="${base%.dylib}"
        local candidate
        candidate="$(find "$arm_lib" -maxdepth 1 -name "${stem}*.dylib" | head -1)"
        if [[ -n "$candidate" && "$candidate" != "$arm_lib/$base" ]]; then
            echo "  rename $(basename "$candidate") -> $base"
            mv "$candidate" "$arm_lib/$base"
        fi
    done
    shopt -u nullglob

    echo "=== Normalizing @executable_path install names ==="
    while read -r file; do
        local id
        if [[ "$file" == *.dylib ]]; then
            id="${PDFTOPS_RPATH}/$(basename "$file")"
            install_name_tool -id "$id" "$file"
        fi
        # 依存パスを既存構成に合わせる
        while read -r dep; do
            [[ -z "$dep" ]] && continue
            local base
            base="$(basename "$dep")"
            if [[ "$dep" == @executable_path/* ]]; then
                install_name_tool -change "$dep" "${PDFTOPS_RPATH}/${base}" "$file" 2>/dev/null || true
            fi
        done < <(otool -L "$file" | awk 'NR>1 {print $1}' | grep -v '^/usr/lib' || true)
    done < <(macho_files_under "$ARM64_STAGE")

    echo "=== Forcing arm64 min OS metadata to $ARM64_MIN_OS ==="
    while read -r file; do
        set_arm64_minos_metadata "$file"
    done < <(macho_files_under "$ARM64_STAGE")
}

build_arm64() {
    check_build_prereqs
    fetch_poppler
    apply_arm64_deployment_target

    echo "=== Building Poppler $POPPLER_VERSION (arm64, min OS $ARM64_MIN_OS) ==="
    echo "    MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET"
    echo "    CMAKE_OSX_DEPLOYMENT_TARGET=$CMAKE_OSX_DEPLOYMENT_TARGET"

    cmake -S "$POPPLER_SRC" -B "$POPPLER_BUILD" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$POPPLER_PREFIX" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$ARM64_MIN_OS" \
        -DCMAKE_C_FLAGS="-mmacosx-version-min=${ARM64_MIN_OS}" \
        -DCMAKE_CXX_FLAGS="-mmacosx-version-min=${ARM64_MIN_OS}" \
        -DCMAKE_EXE_LINKER_FLAGS="-mmacosx-version-min=${ARM64_MIN_OS}" \
        -DCMAKE_SHARED_LINKER_FLAGS="-mmacosx-version-min=${ARM64_MIN_OS}" \
        -DENABLE_NSS=ON \
        -DENABLE_GPG=OFF \
        -DENABLE_BOOST=OFF

    cmake --build "$POPPLER_BUILD" --target pdftops -j "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
    cmake --install "$POPPLER_BUILD"

    if [[ ! -x "$POPPLER_PREFIX/bin/pdftops" ]]; then
        echo "ERROR: pdftops not built: $POPPLER_PREFIX/bin/pdftops" >&2
        exit 1
    fi

    echo "=== Staging arm64 bundle ==="
    stage_arm64_bundle

    echo ""
    echo "arm64 stage ready: $ARM64_STAGE"
    xcrun llvm-otool -l "$ARM64_STAGE/pdftops" 2>/dev/null | awk '/minos|version/{print}' | head -4 || true
}

lipo_merge() {
    [[ -d "$X86_SRC" ]] || { echo "ERROR: x86_64 source missing: $X86_SRC" >&2; exit 1; }
    [[ -d "$ARM64_STAGE/pdftops" ]] || { echo "ERROR: arm64 stage missing. Run: $0 arm64" >&2; exit 1; }

    rm -rf "$UNIVERSAL_OUT"
    mkdir -p "$UNIVERSAL_OUT/pdftops-lib"
    cp "$X86_SRC/Xpdf.license" "$UNIVERSAL_OUT/" 2>/dev/null || true

    echo "=== lipo merge (x86_64 + arm64 -> universal) ==="
    while read -r x86_file; do
        local rel="${x86_file#$X86_SRC/}"
        local arm_file="$ARM64_STAGE/$rel"
        local out_file="$UNIVERSAL_OUT/$rel"
        mkdir -p "$(dirname "$out_file")"

        if [[ ! -f "$arm_file" ]]; then
            echo "ERROR: missing arm64 counterpart: $rel" >&2
            exit 1
        fi

        local x86_thin arm_thin
        x86_thin="$(mktemp -t x86.XXXXXX)"
        arm_thin="$(mktemp -t arm.XXXXXX)"
        lipo -thin x86_64 "$x86_file" -output "$x86_thin"
        lipo -thin arm64 "$arm_file" -output "$arm_thin"
        lipo -create "$x86_thin" "$arm_thin" -output "$out_file"
        chmod +x "$out_file" 2>/dev/null || true
        rm -f "$x86_thin" "$arm_thin"
        echo "  $rel"
    done < <(macho_files_under "$X86_SRC")

    echo ""
    echo "Universal tree: $UNIVERSAL_OUT"
}

verify_universal() {
    REQUIRE_UNIVERSAL=1 REQUIRE_ARM64_MIN_OS_EXACT=1 \
        "$SCRIPT_DIR/verify-universal.sh" "$UNIVERSAL_OUT"
}

install_universal() {
    verify_universal
    local backup="$PROJECT_DIR/Resources/pdftops.backup.$(date +%Y%m%d%H%M%S)"
    echo "=== Backing up current pdftops -> $backup ==="
    cp -R "$X86_SRC" "$backup"
    echo "=== Installing universal tree -> $X86_SRC ==="
    rsync -a --delete "$UNIVERSAL_OUT/" "$X86_SRC/"
    echo "Done. Backup: $backup"
}

cmd="${1:-}"
case "$cmd" in
    fetch) fetch_poppler ;;
    arm64) build_arm64 ;;
    lipo) lipo_merge ;;
    verify) verify_universal ;;
    install) install_universal ;;
    all)
        build_arm64
        lipo_merge
        verify_universal
        echo ""
        echo "Next: $0 install   # to update Resources/pdftops"
        ;;
    -h|--help|help|"") usage 0 ;;
    *) echo "Unknown command: $cmd" >&2; usage 1 ;;
esac