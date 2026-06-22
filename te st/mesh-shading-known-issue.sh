#!/bin/bash
# pgfplots 3D surf（メッシュシェーディング）の既知問題を再現する。
# 80 件の回帰テストとは別扱い。run_verified_tests.py から呼ばれる。
set -euo pipefail
./tex2img --resolution 6 --workingdir current --with-text pgfplots-surf.pdf ./mesh-shading/out.pdf