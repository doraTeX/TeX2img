#!/bin/bash
# 両CPUの最低OSを本体の deployment target と比較する。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-${DERIVED_DATA:-$HOME/Developer/DerivedData/TeX2img}/Build/Products/Release/TeX2img.app}"
exec python3 "$SCRIPT_DIR/verify-universal.py" "$TARGET"
