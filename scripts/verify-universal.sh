#!/bin/bash
# Verify Mach-O files are universal (arm64 + x86_64) and arm64 min OS is acceptable.
#
# Usage:
#   scripts/verify-universal.sh [path]
#     path: TeX2img.app, pdftops directory, or any directory tree (default: Release app)
#
# Environment:
#   ARM64_MIN_OS=11.0   — arm64 スライスがこの版以上を要求していないか（上限も同値で検査）
#   REQUIRE_UNIVERSAL=1 — thin バイナリをエラーにする（デフォルト 1）
#   X86_REFERENCE_DIR   — x86 側に存在しない arm64-only ヘルパーを許容する参照ツリー
#                         （未指定時は Resources/pdftops.backup.* の最新を自動採用）
#
# Thin で許容する例外:
#   - libswift*.dylib (x86_64 のみ) — Intel / 低い macOS 向けレガシー Swift 同梱。
#     arm64 は /usr/lib/swift を参照するため同梱不要。将来の最低 OS 引き上げで消える。
#   - pdftops-lib 内の arm64-only ヘルパー — X86_REFERENCE_DIR に無いもの
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/pdftops-build-env.sh
source "$SCRIPT_DIR/lib/pdftops-build-env.sh"

TARGET="${1:-}"
ARM64_MIN_OS="${ARM64_MIN_OS:-11.0}"
REQUIRE_UNIVERSAL="${REQUIRE_UNIVERSAL:-1}"

if [[ -z "${X86_REFERENCE_DIR:-}" ]]; then
    X86_REFERENCE_DIR="$(find "$PROJECT_DIR/Resources" -maxdepth 1 -type d -name 'pdftops.backup.*' 2>/dev/null | sort | tail -1)"
fi

if [[ -z "$TARGET" ]]; then
    DERIVED_DATA="${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}"
    TARGET="$DERIVED_DATA/Build/Products/Release/TeX2img.app"
fi
[[ -e "$TARGET" ]] || { echo "ERROR: Not found: $TARGET" >&2; exit 1; }

is_macho() {
    file -b "$1" 2>/dev/null | grep -q Mach-O
}

minos_from_macho() {
    local file="$1"
    local minos=""
    if minos="$(vtool -show-build "$file" 2>/dev/null | awk '/minos/{print $2; exit}')"; then
        :
    elif minos="$(xcrun llvm-otool -l "$file" 2>/dev/null | awk '/version/{print $2; exit}')"; then
        :
    fi
    [[ -n "$minos" ]] || return 1
    echo "$minos"
}

minos_for_slice() {
    local file="$1"
    local arch="$2"
    local thin=""
    local probe="$file"

    thin="$(mktemp -t "verify-${arch}.XXXXXX")"
    if lipo -thin "$arch" "$file" -output "$thin" 2>/dev/null; then
        probe="$thin"
    else
        local sole
        sole="$(arch_list "$file")"
        [[ "$sole" == "$arch" ]] || { rm -f "$thin"; return 1; }
    fi

    local minos=""
    minos="$(minos_from_macho "$probe")" || { rm -f "$thin"; return 1; }
    rm -f "$thin"
    echo "$minos"
}

is_legacy_swift_lib() {
    local rel="$1"
    local has_arm64="$2"
    local has_x86="$3"
    local base
    base="$(basename "$rel")"
    [[ "$has_arm64" == 0 && "$has_x86" == 1 && "$base" == libswift*.dylib ]]
}

arch_list() {
    local file="$1"
    local info
    info="$(lipo -info "$file" 2>&1)"
    if [[ "$info" == *"Architectures in the fat file"* ]]; then
        echo "$info" | sed -E 's/.*are: //'
    elif [[ "$info" == *"Non-fat file"* ]]; then
        echo "$info" | sed -E 's/.*architecture: //'
    fi
}

arm64_minos_ok() {
    # arm64 は minos=11.0 を目標とする。
    # ホスト OS が入ると 15.x / 26.x になり要件が厳しすぎる → 11.0 より大きければ NG。
    # 10.x は arm64 ポリシー（11+）より緩い → 警告扱いだが CI では NG にできる。
    python3 - "$1" "$2" <<'PY'
import sys

def parse(v):
    parts = v.split(".")
    return tuple(int(p) for p in parts)

minos, target = parse(sys.argv[1]), parse(sys.argv[2])
if minos > target:
    print("high")   # 厳しすぎ (例: 26.5)
elif minos < target:
    print("low")    # 緩い (例: 10.13)
else:
    print("ok")
PY
}

scan_root() {
    if [[ -f "$1" ]]; then
        echo "$1"
        return
    fi
    find "$1" -type f 2>/dev/null
}

errors=0
checked=0
universal_ok=0
thin_ok=0
legacy_swift_ok=0
arm64_helper_ok=0
arm64_minos_pass=0
arm64_minos_bad=0

echo "=== Universal / min OS verification ==="
echo "Target:         $TARGET"
echo "ARM64_MIN_OS:   $ARM64_MIN_OS"
[[ -n "${X86_REFERENCE_DIR:-}" ]] && echo "X86 reference:  $X86_REFERENCE_DIR"
echo ""

while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    is_macho "$file" || continue
    checked=$((checked + 1))

    rel="${file#$TARGET/}"
    [[ "$rel" == "$file" ]] && rel="$(basename "$file")"
    archs="$(arch_list "$file")"
    has_arm64=0
    has_x86=0
    [[ " $archs " == *" arm64 "* ]] && has_arm64=1
    [[ " $archs " == *" x86_64 "* ]] && has_x86=1

    if [[ "$has_arm64" == 1 && "$has_x86" == 1 ]]; then
        universal_ok=$((universal_ok + 1))
        status="universal"
    else
        thin_ok=$((thin_ok + 1))
        status="thin($archs)"
        if [[ "$REQUIRE_UNIVERSAL" == "1" ]]; then
            if is_legacy_swift_lib "$rel" "$has_arm64" "$has_x86"; then
                legacy_swift_ok=$((legacy_swift_ok + 1))
                echo "  OK  $rel — x86_64-only legacy Swift embed (arm64 uses /usr/lib/swift)"
                continue
            fi
            x86_ref="${X86_REFERENCE_DIR:-}"
            if [[ -n "$x86_ref" && "$has_arm64" == 1 && "$has_x86" == 0 \
                  && ! -f "$x86_ref/$rel" ]]; then
                arm64_helper_ok=$((arm64_helper_ok + 1))
                minos="$(minos_for_slice "$file" arm64 || true)"
                if [[ -n "$minos" ]]; then
                    echo "  OK  $rel — arm64-only helper (not in x86 reference) arm64_min=$minos"
                else
                    echo "  OK  $rel — arm64-only helper (not in x86 reference)"
                fi
                continue
            fi
            echo "ERROR: not universal: $rel ($archs)" >&2
            errors=$((errors + 1))
        fi
    fi

    if [[ "$has_arm64" == 1 ]]; then
        minos="$(minos_for_slice "$file" arm64 || true)"
        if [[ -z "$minos" ]]; then
            echo "ERROR: cannot read arm64 min OS: $rel" >&2
            errors=$((errors + 1))
            arm64_minos_bad=$((arm64_minos_bad + 1))
        else
            case "$(arm64_minos_ok "$minos" "$ARM64_MIN_OS")" in
                ok)
                    arm64_minos_pass=$((arm64_minos_pass + 1))
                    status="$status arm64_min=$minos"
                    ;;
                low)
                    echo "WARNING: arm64 min OS below target: $rel (minos=$minos, want $ARM64_MIN_OS)" >&2
                    if [[ "${REQUIRE_ARM64_MIN_OS_EXACT:-1}" == "1" ]]; then
                        echo "ERROR: arm64 min OS must be $ARM64_MIN_OS: $rel" >&2
                        errors=$((errors + 1))
                        arm64_minos_bad=$((arm64_minos_bad + 1))
                    else
                        arm64_minos_pass=$((arm64_minos_pass + 1))
                        status="$status arm64_min=$minos(low)"
                    fi
                    ;;
                high)
                    echo "ERROR: arm64 min OS too high: $rel (minos=$minos, want $ARM64_MIN_OS)" >&2
                    echo "       Build with MACOSX_DEPLOYMENT_TARGET=$ARM64_MIN_OS" >&2
                    errors=$((errors + 1))
                    arm64_minos_bad=$((arm64_minos_bad + 1))
                    ;;
            esac
        fi
    fi

    if [[ "$REQUIRE_UNIVERSAL" != "1" || "$status" == universal* ]]; then
        echo "  OK  $rel — $status"
    fi
done < <(scan_root "$TARGET")

echo ""
echo "=== Summary ==="
echo "Mach-O checked:     $checked"
echo "Universal:          $universal_ok"
echo "Thin:               $thin_ok"
echo "Legacy Swift embed: $legacy_swift_ok"
echo "arm64-only helper:  $arm64_helper_ok"
echo "arm64 min OS OK:    $arm64_minos_pass"
echo "arm64 min OS error: $arm64_minos_bad"

if [[ "$errors" -gt 0 ]]; then
    echo ""
    echo "FAILED ($errors errors)" >&2
    exit 1
fi

echo ""
echo "OK"