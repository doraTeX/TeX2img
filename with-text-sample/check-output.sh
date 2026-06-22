#!/bin/bash
# output-with-text.pdf が正しく生成されているか簡易診断
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$SCRIPT_DIR/output-with-text.pdf"
REFERENCE="$SCRIPT_DIR/reference-lualatex.pdf"

if [[ ! -f "$OUTPUT" ]]; then
    echo "error: $OUTPUT がありません。先に ./run.sh を実行してください。" >&2
    exit 1
fi

SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT")
HEADER=$(head -c 8 "$OUTPUT")

echo "file   : $OUTPUT"
echo "size   : $SIZE bytes"
echo "header : $HEADER"

if [[ "$SIZE" -lt 500000 ]]; then
    echo "判定   : NG — ファイルが小さすぎます（アウトライン化 PDF の可能性大）"
    echo "対処   : ./run.sh を再実行するか、GUI で「テキスト埋め込み PDF」を ON にしてください。"
    exit 1
fi

if [[ -f "$SCRIPT_DIR/run.log" ]] && grep -q "sDEVICE=pdfwrite" "$SCRIPT_DIR/run.log"; then
    echo "判定   : NG — run.log に pdfwrite（アウトライン化）が記録されています"
    exit 1
fi

if [[ -f "$SCRIPT_DIR/run.log" ]] && ! grep -q "Text embedded PDF: enabled" "$SCRIPT_DIR/run.log"; then
    echo "判定   : NG — --with-text が効いていません"
    exit 1
fi

echo "判定   : OK — サイズ・ログ上はテキスト埋め込み PDF 経路"

if [[ -f "$REFERENCE" ]]; then
    REF_SIZE=$(stat -f%z "$REFERENCE" 2>/dev/null || stat -c%s "$REFERENCE")
    echo "参考   : reference-lualatex.pdf ($REF_SIZE bytes)"
    echo "注意   : pgfplots の surf+thin はメッシュ境界線が見えることがあります。"
    echo "         完全な線のみのワイヤーフレームとは異なります。"
fi