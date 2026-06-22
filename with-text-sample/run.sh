#!/bin/bash
# pgfplots 3D surf を TeX2img で PDF 化する（--with-text 必須）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SAMPLE_TEX="$SCRIPT_DIR/sample.tex"
OUTPUT_PDF="$SCRIPT_DIR/output-with-text.pdf"
REFERENCE_PDF="$SCRIPT_DIR/reference-lualatex.pdf"
LOG_FILE="$SCRIPT_DIR/run.log"
DERIVED_DATA="/tmp/tex2img-with-text-sample-DerivedData"
MIN_OUTPUT_BYTES=500000

# TeX Live（優先順で探索）
TEXBIN=""
for candidate in \
    "/Applications/TeXLive/2026/bin/universal-darwin" \
    "/Library/TeX/texbin" \
    "/usr/local/texlive/2025/bin/universal-darwin" \
    "/usr/local/texlive/2024/bin/universal-darwin"; do
    if [[ -x "$candidate/lualatex" ]]; then
        TEXBIN="$candidate"
        break
    fi
done
if [[ -z "$TEXBIN" ]]; then
    echo "error: lualatex が見つかりません。TeX Live をインストールしてください。" >&2
    exit 1
fi

build_tex2img() {
    echo "tex2img CUI をビルドしています..."
    xcodebuild \
        -project "$PROJECT_DIR/TeX2img.xcodeproj" \
        -scheme "tex2img CUI" \
        -configuration Debug \
        -derivedDataPath "$DERIVED_DATA" \
        build > "$SCRIPT_DIR/xcodebuild.log" 2>&1
}

find_tex2img() {
    local -a candidates=(
        "$DERIVED_DATA/Build/Products/Debug/tex2img"
        "/tmp/tex2img-build/Build/Products/Debug/tex2img"
    )
    local dd
    for dd in "$HOME/Library/Developer/Xcode/DerivedData"/TeX2img-*/Build/Products/Debug/tex2img; do
        [[ -e "$dd" ]] && candidates+=("$dd")
    done

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

TEX2IMG="$(find_tex2img || true)"
if [[ -z "$TEX2IMG" ]]; then
    build_tex2img
    TEX2IMG="$DERIVED_DATA/Build/Products/Debug/tex2img"
fi
if [[ ! -x "$TEX2IMG" ]]; then
    echo "error: tex2img のビルドに失敗しました。xcodebuild.log を確認してください。" >&2
    exit 1
fi

# mudraw 用 TeX2img.app
APP="$(dirname "$TEX2IMG")/TeX2img.app"
if [[ ! -d "$APP" ]]; then
    APP_CANDIDATE="$(find "$DERIVED_DATA/Build/Products/Debug" "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Debug/TeX2img.app" 2>/dev/null | head -1)"
    [[ -n "$APP_CANDIDATE" ]] && APP="$APP_CANDIDATE"
fi
if [[ -d "$APP" ]]; then
    ln -sf "$APP" "$SCRIPT_DIR/TeX2img.app"
fi

export PATH="$TEXBIN:$PATH"

echo "TeX bin : $TEXBIN"
echo "tex2img : $TEX2IMG"
"$TEX2IMG" --version 2>&1 | head -1 || true
echo "input   : $SAMPLE_TEX"
echo "output  : $OUTPUT_PDF"
echo "log     : $LOG_FILE"
echo

# 比較用: lualatex 直接出力
echo "参考 PDF を lualatex で生成: $REFERENCE_PDF"
lualatex -interaction=nonstopmode -output-directory="$SCRIPT_DIR" "$SAMPLE_TEX" > "$SCRIPT_DIR/lualatex.log" 2>&1 || true
if [[ -f "$SCRIPT_DIR/sample.pdf" ]]; then
    mv -f "$SCRIPT_DIR/sample.pdf" "$REFERENCE_PDF"
fi

rm -f "$OUTPUT_PDF"
{
    echo "===== $(date) ====="
    "$TEX2IMG" \
        --latex lualatex \
        --gs rungs \
        --with-text \
        --no-merge-output-files \
        --resolution 15 \
        "$SAMPLE_TEX" \
        "$OUTPUT_PDF"
} 2>&1 | tee "$LOG_FILE"

echo
if [[ ! -f "$OUTPUT_PDF" ]]; then
    echo "error: 出力 PDF が生成されませんでした。" >&2
    exit 1
fi

OUTPUT_SIZE=$(stat -f%z "$OUTPUT_PDF" 2>/dev/null || stat -c%s "$OUTPUT_PDF")
REFERENCE_SIZE=0
[[ -f "$REFERENCE_PDF" ]] && REFERENCE_SIZE=$(stat -f%z "$REFERENCE_PDF" 2>/dev/null || stat -c%s "$REFERENCE_PDF")

echo "出力サイズ       : $OUTPUT_SIZE bytes"
[[ "$REFERENCE_SIZE" -gt 0 ]] && echo "参考 (lualatex)  : $REFERENCE_SIZE bytes"

if ! grep -q "Text embedded PDF: enabled" "$LOG_FILE"; then
    echo
    echo "error: --with-text が効いていません（ログに 'Text embedded PDF: enabled' がありません）。" >&2
    echo "  別の tex2img バイナリを使っていないか確認してください。" >&2
    exit 1
fi

if grep -q "sDEVICE=pdfwrite" "$LOG_FILE"; then
    echo
    echo "error: アウトライン化 PDF 経路（pdfwrite）が使われています。" >&2
    echo "  --with-text が無効になっています。GUI の場合は「テキスト埋め込み PDF」にチェックを入れてください。" >&2
    exit 1
fi

if [[ "$OUTPUT_SIZE" -lt "$MIN_OUTPUT_BYTES" ]]; then
    echo
    echo "error: 出力 PDF が小さすぎます（${OUTPUT_SIZE} bytes < ${MIN_OUTPUT_BYTES} bytes）。" >&2
    echo "  アウトライン化 PDF 経路になっている可能性があります。" >&2
    echo "  期待値: おおよそ 1 MB 以上（参考 lualatex: ${REFERENCE_SIZE} bytes）" >&2
    exit 1
fi

echo
echo "OK: output-with-text.pdf はテキスト埋め込み PDF 経路で生成されました。"
echo "    Preview で reference-lualatex.pdf と見た目を比較してください。"
ls -la "$OUTPUT_PDF" "$REFERENCE_PDF" 2>/dev/null || ls -la "$OUTPUT_PDF"