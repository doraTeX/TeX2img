#!/bin/bash
# PDFKit 再現テスト: TeX2img の pdfcrop / embed と同じ操作を段階的に試す
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INPUT="$SAMPLE_DIR/reference-lualatex.pdf"
OUT_DIR="$SCRIPT_DIR/output"
BIN="$SCRIPT_DIR/pdfkit-repro"

if [[ ! -f "$INPUT" ]]; then
    echo "error: $INPUT がありません。先に ../run.sh を実行してください。" >&2
    exit 1
fi

echo "=== build ==="
swiftc "$SCRIPT_DIR/main.swift" -o "$BIN" -framework PDFKit -framework AppKit -framework Foundation

mkdir -p "$OUT_DIR"
export PATH="/Applications/TeXLive/2026/bin/universal-darwin:/Library/TeX/texbin:$PATH"

analyze() {
    python3 - "$1" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_bytes().decode('latin1')
print(f"    header={text[:8]!r}  ShadingType4={text.count('ShadingType 4')}  PatternType1={text.count('PatternType 1')}")
PY
}

echo
echo "=== 入力 (reference-lualatex.pdf) ==="
analyze "$INPUT"

for mode in rewrite crop embed crop-and-embed cg-draw; do
    out="$OUT_DIR/${mode}.pdf"
    echo
    echo "=== PDFKit: $mode ==="
    "$BIN" --mode "$mode" "$INPUT" "$out"
    analyze "$out"
done

echo
echo "=== 非 PDFKit 経路（比較用） ==="

cp "$INPUT" "$OUT_DIR/passthrough.pdf"
echo "passthrough (cp):"
analyze "$OUT_DIR/passthrough.pdf"

(cd "$SAMPLE_DIR" && pdfcrop -q reference-lualatex.pdf "$OUT_DIR/pdfcrop-cli.pdf")
echo "pdfcrop (TeX Live CLI):"
analyze "$OUT_DIR/pdfcrop-cli.pdf"

qpdf "$INPUT" "$OUT_DIR/qpdf-copy.pdf" 2>/dev/null
echo "qpdf (stream copy):"
analyze "$OUT_DIR/qpdf-copy.pdf"

gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.7 \
   -sOutputFile="$OUT_DIR/gs-pdfwrite.pdf" "$INPUT" 2>/dev/null
echo "Ghostscript pdfwrite:"
analyze "$OUT_DIR/gs-pdfwrite.pdf"

if [[ -f "$SAMPLE_DIR/output-with-text.pdf" ]]; then
    echo "TeX2img --with-text 実出力:"
    analyze "$SAMPLE_DIR/output-with-text.pdf"
fi

echo
echo "=== Preview 書き出しとの比較用 ==="
echo "Preview で $INPUT を開き、「ファイル → 書き出す…」で"
echo "  $OUT_DIR/preview-export.pdf"
echo "として保存し、次を実行:"
echo "  python3 -c \"t=open('$OUT_DIR/preview-export.pdf','rb').read().decode('latin1'); print('ShadingType4',t.count('ShadingType 4'),'PatternType1',t.count('PatternType 1'))\""