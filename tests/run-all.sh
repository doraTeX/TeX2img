#!/bin/bash
# tests/ の試験を順に実行する。
#
# 使い方:
#   tests/run-all.sh [--app path/to/TeX2img.app] [--work-root 同梱ツールのビルド先]
#
# --app を付けると，アプリに同梱した CLI を使う試験も実行する（pdflatex・platex・gs が PATH に要る）。
# --work-root を付けると，同梱ツールのソースを検査する試験も実行する。
# 付けなかった試験は「SKIP」と表示する。どの試験も画面にウインドウを出さない。
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP=""
WORK_ROOT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --app) APP="$2"; shift 2 ;;
        --work-root) WORK_ROOT="$2"; shift 2 ;;
        *) echo "Usage: $0 [--app TeX2img.app] [--work-root DIR]" >&2; exit 2 ;;
    esac
done

PYTHON="${PYTHON:-python3}"
passed=0
failed=0
skipped=0
failures=()

for test in "$ROOT"/tests/test_*.py; do
    [[ -f "$test" ]] || continue
    name="$(basename "$test")"
    args=()
    if grep -q "add_argument('--app'" "$test"; then
        if [[ -z "$APP" ]]; then
            echo "SKIP  $name (--app)"; skipped=$((skipped + 1)); continue
        fi
        args+=(--app "$APP")
    fi
    if grep -q "add_argument('--work-root'" "$test"; then
        if [[ -z "$WORK_ROOT" ]]; then
            echo "SKIP  $name (--work-root)"; skipped=$((skipped + 1)); continue
        fi
        args+=(--work-root "$WORK_ROOT")
    fi
    log="$(mktemp -t tex2img-test)"
    start=$SECONDS
    if "$PYTHON" "$test" ${args[@]+"${args[@]}"} >"$log" 2>&1; then
        echo "PASS  $name ($((SECONDS - start))s)"; passed=$((passed + 1))
    else
        echo "FAIL  $name ($((SECONDS - start))s)"; failed=$((failed + 1)); failures+=("$name")
        sed 's/^/      /' "$log" | tail -40
    fi
    rm -f "$log"
done

echo
echo "passed: $passed, failed: $failed, skipped: $skipped"
if [[ $failed -gt 0 ]]; then
    printf 'failed: %s\n' "${failures[@]}"
    exit 1
fi
