## 調査結果: pgfplots 3D `surf` がワイヤーフレーム化する問題（PDFKit 起因・修正保留）

### 現象

LuaLaTeX + pgfplots の 3D `surf`（例: トーラス）を TeX2img で変換すると、Preview で開いたときに**面の塗りが失われ、ワイヤーフレーム状**に見える。

- 同じ PDF を Preview.app で「書き出し」すると**面は保持される**
- LuaLaTeX 直出力の PDF は正常

### 根本原因（調査済み）

**PDFKit / Core Graphics による PDF の再シリアライズ**が原因。TeX2img・Ghostscript・pgfplots のバグではない。

pgfplots 3D `surf` は PDF の **ShadingType 4**（メッシュシェーディング）で面を描画している。`PDFDocument.write(to:)` や `CGContext.drawPDFPage` で PDF を書き直すと、Apple の PDF writer がこれを **PatternType 1** に変換する。Preview では格子状のワイヤーフレームに見える。

| 経路 | ShadingType 4 | PatternType 1 | Preview での見え方 |
|------|:-------------:|:-------------:|-------------------|
| LuaLaTeX 直出力 / Preview 書き出し | あり | なし | 面あり |
| `PDFDocument.write` のみ（`rewrite`） | なし | あり | ワイヤーフレーム |
| TeX2img `--with-text` PDF 出力 | なし | あり | ワイヤーフレーム |
| TeX Live `pdfcrop` CLI / `qpdf` / `gs pdfwrite` | あり | なし | 面あり |

### TeX2img 上の該当箇所

`pdfcrop()` は TeX Live の `pdfcrop` コマンドではなく、内部で `generateCroppedPDF()` → `PDFDocument.writeToFilePath()` を呼んでいる。

- `Sources/Converter/Converter-BoundingBox.swift` — `generateCroppedPDF`
- `Sources/Converter/Converter.swift` — `pdfcrop()`, `embedTeXSource()`
- `Sources/Extensions/PDF/PDFDocument-Extension.swift` — `fillBackground`（`drawPDFPage`）

**影響範囲**

- `--with-text` + PDF 最終出力 — crop と embed の両方で `write` が走る
- PNG 等の最終出力 — 途中の `pdfcrop()` でも `write` が走る（ラスター化前の中間 PDF が壊れる）

### PDFKit で回避できない理由

`PDFDocument.write(to:withOptions:)` の公開オプションに、**出力 PDF バージョンの指定や ShadingType 4 保持の設定はない**。非公開キー（`SaveWithCorePDFLayout` 等）や `dataRepresentation()` でも同じ変換が起きる（`with-text-sample/pdfkit-repro/test-write-options.m` で確認済み）。

### 修正を保留とする理由

crop だけを `qpdf` 等に置き換えても不十分。次も PDFKit `write` / `drawPDFPage` 経路のため、別途置き換えが必要。

1. **背景塗り** — `PDFDocument.fillBackground`（PDF/SVG/EPS + 背景色の一部経路）
2. **PDF 結合** — `PDFDocument(merging:).writeToFilePath`（merge PDF 等）
3. **TeX ソース埋め込み** — `embedTeXSource` → `doc.write()`

既存 80 件の回帰テスト（`te st/test.sh`）はこのケースをカバーしていない。修正には qpdf 同梱と複数箇所の非 PDFKit 化が必要なため、**現時点では修正を保留**とする。

### 再現手順

```bash
cd "te st"
./tex2img --resolution 6 --workingdir current --with-text pgfplots-surf.pdf ./mesh-shading/out.pdf
```

```bash
python3 -c "
for p in 'pgfplots-surf.pdf', 'mesh-shading/out.pdf':
  t = open(p, 'rb').read().decode('latin1')
  print(p, 'ver', t[:8], 'S4', t.count('ShadingType 4'), 'P1', t.count('PatternType 1'))
"
```

**既知状態（バグが残っているとき）**

- 入力 `pgfplots-surf.pdf`: ShadingType 4 が多数、PatternType 1 は 0
- 出力 `mesh-shading/out.pdf`: ShadingType 4 は 0、PatternType 1 が多数

### リポジトリ内の参照

| パス | 内容 |
|------|------|
| `te st/pgfplots-surf.pdf` | 参照入力 PDF |
| `te st/pgfplots-surf.tex` | 元 TeX |
| `te st/mesh-shading-known-issue.sh` | 再現コマンド |
| `te st/verified-tests.md` | 既知の保留事項として文書化 |
| `with-text-sample/pdfkit-repro/` | PDFKit 単体の最小再現（`rewrite` だけで再現） |

`run_verified_tests.py` は 80 件の後にこのチェックを `[DEFERRED]` として別枠実行する（回帰合否には含めない）。

### 将来の修正方針（参考）

| 処理 | 案 |
|------|-----|
| crop | TeX Live `pdfcrop` または qpdf による MediaBox 変更（ストリーム保持） |
| merge | `qpdf --pages` |
| 背景塗り | コンテンツストリーム先頭への矩形注入、または GS 下敷き |
| embed | xattr のみ、または qpdf での注釈注入 |

---

**ステータス:** 既知の問題として文書化済み。修正は保留（`wontfix` / `known-issue` 相当）。