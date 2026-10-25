#!/bin/bash
# 旧スクリプト名の互換入口。両CPU・全依存・MuPDFを同一ソースからビルドする。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "${1:-all}" in
    all) shift "$(( $# > 0 ? 1 : 0 ))"; exec python3 "$SCRIPT_DIR/build-bundled-tools.py" "$@" ;;
    install) shift; exec python3 "$SCRIPT_DIR/build-bundled-tools.py" --install "$@" ;;
    *) echo "Usage: $0 [all|install] [--work-root DIR]" >&2; exit 1 ;;
esac
