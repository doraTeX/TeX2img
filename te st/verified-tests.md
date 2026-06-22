# tex2img 網羅テスト — 使い方（AI 引き継ぎ用）

このディレクトリ（`te st`）は、CUI 版 `tex2img` の回帰テスト用です。ディレクトリ名・入力ファイル名に**わざとスペース**を入れており、スペース入りパスへの耐性も同時に試します。

## ファイル構成

| ファイル | 説明 |
|----------|------|
| `in put.pdf` | 入力 PDF（全 8 ページ。空ページは 1, 3, 5） |
| `pgfplots-surf.pdf` | pgfplots 3D `surf` の参照 PDF（メッシュシェーディング検証用。下記「既知の保留事項」） |
| `pgfplots-surf.tex` | 上記 PDF の元 TeX（`with-text-sample/sample.tex` と同内容） |
| `test.sh` | 80 件のテストコマンド（**丸ごと実行しないこと**） |
| `mesh-shading-known-issue.sh` | メッシュシェーディング既知問題の再現コマンド（**保留・別枠**） |
| `github-comment-mesh-shading.md` | GitHub issue 用コメント（調査結果・保留理由） |
| `list.xlsx` | 各テストの仕様一覧（日本語） |
| `run_verified_tests.py` | **推奨** — `test.sh` を 1 件ずつ実行し、生成物を自動検証 |
| `verified-tests.md` | 本ドキュメント |

テスト実行後に生成される（コミット不要）:

- `test_results.md` / `test_results.json` — 検証結果
- `1/` … `80/` — 各テストの出力ディレクトリ
- `mesh-shading/` — メッシュシェーディング既知問題テストの出力

## 前提条件

- macOS
- Python 3
- `swift`（検証時に `PDFKit` / `AppKit` を `-e` で使用）
- LaTeX ツールチェーン（`platex`, `dvipdfmx`, `gs`, `epstopdf` など）
- 最新 CUI バイナリ `tex2img`（下記ビルド手順参照）
- `TeX2img.app`（同梱 `mudraw` / `pdftops` 用）

**注意:** PATH 上の古い `/usr/local/teTeX/bin/tex2img` は使わないこと。

## 推奨: 隔離テスト環境のセットアップ

リポジトリ直下でテストすると `1/`…`80/` が大量にできるため、`mktemp` したディレクトリで行うのが望ましい。

```bash
# 1. 一時ディレクトリを作成し、この "te st" をコピー
TEST_ROOT=$(mktemp -d /tmp/tex2img-test.XXXXXX)
cp -R "/path/to/TeX2img/te st" "$TEST_ROOT/"
cd "$TEST_ROOT/te st"

# 2. 最新 CUI バイナリを配置
cp ~/Developer/DerivedData/TeX2img/Build/Products/Debug/tex2img ./tex2img
chmod +x ./tex2img

# 3. TeX2img.app を配置（mudraw / pdftops 用）
cp -R ~/Developer/DerivedData/TeX2img/Build/Products/Debug/TeX2img.app ./

# 4. /tmp にコピーした場合: pdftops の dylib に ad-hoc 署名が必要
#    （run_verified_tests.py も起動時に自動実行するが、手動でも可）
find TeX2img.app/Contents/Resources/pdftops -type f \( -perm +111 -o -name '*.dylib' \) \
  -exec codesign -s - --force {} \;
```

### バイナリのビルド

詳細は [`docs/build-and-deploy.md`](../docs/build-and-deploy.md) を参照。

```bash
cd /path/to/TeX2img
./scripts/build.sh tex2img Debug
# 出力: ~/Developer/DerivedData/TeX2img/Build/Products/Debug/tex2img
```

テスト用に GUI バンドル全体が必要な場合は `TeX2img.app` も配置する（CUI は `Contents/SharedSupport/bin/tex2img` に同梱される）。

## テストの実行方法

### 推奨: 自動検証スクリプト（1 件ずつ実行）

`test.sh` を**そのまま** `sh test.sh` しないこと。`run_verified_tests.py` が各コマンドを個別に実行し、都度検証する。

```bash
cd "$TEST_ROOT/te st"
python3 run_verified_tests.py
```

- 終了コード `0` = 全件合格、`1` = 1 件以上失敗
- 進捗は標準出力に `[OK] test 01 (pdf) -> ['ok']` 形式で表示
- 詳細は `test_results.md` と `test_results.json` に出力

### 特定テストだけ再実行したい場合

```bash
# 例: テスト 61 のコマンドだけ（test.sh の 62 行目）
eval "$(sed -n '62p' test.sh | sed 's/;.*//')"
```

または Python から:

```python
from run_verified_tests import *
prepare_environment()
tests = parse_tests()
t = next(x for x in tests if x.number == 61)
# ... run_command / verify_outputs を個別に呼ぶ
```

## 入力 PDF の期待動作

`in put.pdf` は 8 ページあるが、中身のあるページは **2, 4, 6, 7, 8** の 5 ページ。1, 3, 5 は空ページ。

| 条件 | 期待される出力ページ |
|------|----------------------|
| 余白なし（`--margins` なし） | 2, 4, 6, 7, 8 のみ（空ページはスキップ） |
| 余白あり（`--margins 10`） | 1〜8 すべて（1, 3, 5 は白ページとして生成。警告メッセージあり） |

no-merge 時のファイル名:

- ページ 1 → `sam ple.<ext>`（拡張子のみ、`-1` なし）
- ページ 2 以降 → `sam ple-2.<ext>`, `sam ple-4.<ext>`, …

## test.sh のテスト一覧（80 件）

| 番号 | 形式 | 主なバリエーション |
|------|------|-------------------|
| 1–8 | PDF | merge / no-merge, 透過 / CCFFCC, 余白, with-text |
| 9–16 | PDF | 上記 + no-with-text（アウトライン化） |
| 17–28 | SVG | 上記 + アニメーション merge（25–28） |
| 29–36 | EPS | plain-text / no-plain-text |
| 37–48 | PNG / JPG / BMP | 透過 / CCFFCC 背景 |
| 49–64 | TIFF / GIF | no-quick + アニメーション merge |
| 65–80 | TIFF / GIF | quick + アニメーション merge |

各テストの詳細仕様は `list.xlsx` を参照。

## run_verified_tests.py の検証内容

1. **終了コード**が 0 であること
2. **出力ファイルの存在**と最小サイズ
3. **ページ番号**が上表の期待と一致すること
4. 形式別の追加チェック:
   - **PDF**: ページ数（merge 時は結合後のページ数）
   - **ビットマップ** (PNG/JPG/BMP/GIF/TIFF): 透過・CCFFCC 背景（四隅サンプル）、中身の有無
   - **SVG**: XML 妥当性、`--delete-display-size` 時の width 除去、アニメーション要素
   - **EPS**: `%!` ヘッダ

### アニメーション GIF（テスト 61–64, 77–80）の縦横比

merge 時は各ページの GIF を**等倍・中央配置**（レターボックス）で結合する。ページごとにサイズが異なるため、キャンバスは全フレームの最大幅×最大高さになる。数式本体が引き伸ばされていないかは、個別出力（例: 57 vs 61）のコンテンツ bbox で比較するとよい。

## 既知の保留事項: pgfplots 3D surf のワイヤーフレーム化（PDFKit）

`pgfplots-surf.pdf` は LuaLaTeX + pgfplots の 3D `surf`（トーラス）を 1 ページにした参照 PDF です。Preview で開くと**面の塗り**が表示されますが、TeX2img の `--with-text` 経路（および PNG 等の途中で `pdfcrop()` → `generateCroppedPDF()` を通る経路）では **ワイヤーフレーム状**に見えることがあります。

### 原因（調査済み・**対処保留**）

| 項目 | 内容 |
|------|------|
| 根本原因 | **PDFKit / Core Graphics による PDF の再シリアライズ**（`PDFDocument.write` や `CGContext.drawPDFPage`） |
| 破壊の内容 | 入力の **ShadingType 4**（メッシュシェーディング）が **PatternType 1** に変換され、PDF 1.7 → 1.3 相当に下がる |
| TeX2img 上の該当箇所 | `generateCroppedPDF` → `writeToFilePath`、`embedTeXSource` → `doc.write`、`PDFDocument.fillBackground` |
| Ghostscript / LuaLaTeX | 原因ではない（`gs pdfwrite` や TeX Live `pdfcrop` CLI は面を保持） |
| Preview.app「書き出し」 | 保持する（Apple 内部の別経路） |

**PDFKit の公開 API では PDF バージョン指定や ShadingType 4 保持の回避策がなく**、crop・背景塗り・PDF 結合・ソース埋め込みの各段階で `write` を避ける大規模な置き換え（qpdf / ストリーム注入など）が必要になるため、**現時点では修正を保留**とする。

### 再現用ファイル

| パス | 説明 |
|------|------|
| `te st/pgfplots-surf.pdf` | 参照入力（ShadingType 4 あり） |
| `te st/mesh-shading-known-issue.sh` | `--with-text` で PDF 出力する再現コマンド |
| `with-text-sample/pdfkit-repro/` | PDFKit 単体での最小再現（`rewrite` だけで再現） |

手動再現:

```bash
cd "$TEST_ROOT/te st"
./mesh-shading-known-issue.sh
python3 -c "
t=open('pgfplots-surf.pdf','rb').read().decode('latin1')
u=open('mesh-shading/out.pdf','rb').read().decode('latin1')
print('input  S4', t.count('ShadingType 4'), 'P1', t.count('PatternType 1'))
print('output S4', u.count('ShadingType 4'), 'P1', u.count('PatternType 1'))
"
```

期待される**現状の既知状態**（バグが残っているとき）:

- 入力: `ShadingType 4` が多数（例: 1500 前後）、`PatternType 1` は 0
- 出力: `ShadingType 4` が 0、`PatternType 1` が多数

`run_verified_tests.py` は 80 件の後にこのチェックを**別枠**で実行する。構造が上記のとおりなら `[DEFERRED]` と表示し、**80 件の合否には含めない**。将来修正して出力が ShadingType 4 を保持するようになったら `[FIXED?]` と表示する（ドキュメントと実装の更新が必要）。

## 既知の環境トラブル

| 症状 | 原因と対処 |
|------|------------|
| plain-text EPS（33–36）が `pdftops cannot be found` | `TeX2img.app` を同ディレクトリに置き、PATH に `pdftops` を追加。`run_verified_tests.py` が自動設定 |
| `Abort trap: 6`（pdftops / libpoppler） | `/tmp` へコピー後に dylib のコード署名が無効。`prepare_environment()` の codesign を実行 |
| 古い tex2img が動く | `which tex2img` を確認。必ず `./tex2img`（同ディレクトリの最新ビルド）を使う |

## AI エージェント向けチェックリスト

作業を引き継ぐ場合は次の順で進めること:

1. `./scripts/safe-build.sh tex2img` で最新バイナリをビルド
2. `mktemp` 環境に `te st`・`tex2img`・`TeX2img.app` を配置
3. `python3 run_verified_tests.py` を実行（**test.sh 一括実行は禁止**）
4. 失敗があれば `test_results.md` のログを読み、個別コマンドを手動再現
5. 修正後は該当テスト番号だけ再実行してからフルスイートを回す
6. 末尾の `[DEFERRED] mesh-shading` は pgfplots surf の PDFKit 既知問題（**保留・合否に含めない**）。`[FIXED?]` が出たら修正済みの可能性あり

## 関連するソース修正（参考）

- アニメ GIF merge の縦横比: `Sources/Converter/Converter.swift` の `generateAnimatedGIF` / `normalizedGIFFrame`
- 透明 GIF/BMP のエンコード: PNG 経由（`gif89aData` / `pdf2image`）