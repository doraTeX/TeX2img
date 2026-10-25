# 同梱ライブラリ更新後の本機検証（2026-10-25）

[ライブラリ更新・Brotli修正の監査](bundled-libraries-2026-10-25.md)に対する追加の実行検証。
実機はApple Silicon、macOS 27.0.1（26A434）、Xcode 27.1（27A9275）。
Intel側はRosettaで実行した。macOS 12およびIntel実機での検証とは区別する。

## 検証方法

- 既存 `te st/test.sh` の80コマンドを、`run_verified_tests.py` で1件ずつ実行して生成物を検査。
- arm64とx86_64それぞれについて、CLIだけでなくpdftopsとmudrawもテスト用コピーをthin化して実行。子プロセスが意図せずnative CPUになるのを避けた。
- 全実行ログでpdftops・mudraw・epstopdfがテスト対象アプリ内を指すことを照合。
- 配布用Universalアプリは変更せず、別途全体の署名・両CPU・最低OSを検査。
- 入出力名に空白、日本語を含むケースを実施。テストは隔離した一時ディレクトリ内で行った。

再現用ランナーを `tests/run_universal_conversion_suite.py` に追加した。
`--output` は未作成ディレクトリを指定する。

```sh
export PATH="$HOME/Library/Frameworks/TetsuPython.framework/Versions/Current/bin:/usr/local/tetex/bin:$PATH"
python3 -u tests/run_universal_conversion_suite.py --app /path/to/TeX2img.app --arch arm64 --output /tmp/new-test-arm64
python3 -u tests/run_universal_conversion_suite.py --app /path/to/TeX2img.app --arch x86_64 --output /tmp/new-test-intel
python3 tests/test_bundled_app.py --app /path/to/TeX2img.app
python3 tests/test_bundled_input_formats.py --app /path/to/TeX2img.app
```

## 検査中に修正した箇所

初回は各CPUで76/80件合格。次の実装・検査の問題を修正した。

1. **背景付きアウトラインSVG（22・24）**: Ghostscriptによるアウトライン化後にQuartzで背景を合成すると、描画状態の参照が壊れ、MuPDFが非ゼロ終了するページがあった。背景合成をアウトライン化前に移し、SVG変換の失敗を呼び出し元へ伝えるようにした。エラーを無視してサイズ削除を飛ばすことがなくなった。
2. **透明な先頭フレームのGIF（63・79）**: 生成物には後続フレームの内容があったが、検査側が先頭だけを調べて空と判定していた。ImageIOで全フレームを検査するよう修正した。
3. **PS/EPS直接入力（追加検査）**: DVI経由だけで設定される入力日時を、直接入力でも参照していた。Ghostscriptの正常終了後に失敗と誤判定していたため、PS変換直前に日時を取得するよう修正した。

`test_bundled_app.py` に、SVGを出力した後に非ゼロ終了するツールを使う否定テストを追加。
両CPUで失敗が正しくCLIへ伝わることを確認した。
`test_bundled_input_formats.py` はTeX/PS/EPS入力・SVGZ出力・壊れたPDF・存在しない入力を両CPUで検査する。

## 最終結果

**修正後はarm64 80/80、x86_64 80/80で、計160件の既存仕様検査に合格。**
ただし、下記のPDFKitに起因する構造・再描画の警告は残る。

| 検査 | 結果 |
|---|---|
| PDF/SVG/EPS/PNG/JPEG/BMP/TIFF/GIF、結合、余白、透明、背景色、テキスト保持、quick等 | 80ケース×2 CPU合格 |
| 生成物の追加検査 | 計732ファイル。SVG全112ファイルのXML・ID参照、EPS全104ファイルのGhostscript処理、ビットマップ全396ファイルのデコード・全フレーム検査成功。PDF120ファイルのうち28ファイルはqpdf警告あり |
| PDFのMuPDF再描画 | 120ファイル中112件は終了0、8件はExtGState警告で終了1（詳細は下記） |
| 画像のCPU間比較 | 198組中176組は全フレームのRGBA一致。quick TIFF/GIFの22組・34フレームに差分。最大差分画素率0.5322%、最大平均チャンネル差0.00782/255。単一画素の最大差は255なので完全同一とは扱わない |
| TeX/PS/EPS入力、SVGZ、壊れたPDF・不存在入力 | Releaseで6ケース×2 CPU合格。Debug arm64でも6ケース合格 |
| 同梱アプリの変換・ツール探索・否定テスト | 5形式×2 CPUおよびSVGツール失敗伝播×2 CPU合格 |
| 既存の非変換回帰テスト | エディタ19、警告文4、色解析12、形式識別子11、保存パネル9、拡張子置換8、新旧ドラッグデータ、Appcast最低OS、ツール探索、Universal検査の否定テスト、すべて合格 |
| GUI実操作 | PDF→EPS/SVG、PS→SVG成功。日本語EPSを再描画して目視確認 |
| ビルド・配布物 | 修正版のGUI/CLI Debug/Releaseビルド、Releaseのdeep/strict署名検査、全9 Mach-Oの両CPU・最低OS・依存検査に合格 |
| Brotli修正 | 両CPUでASan/UBSan付き不正block switchテスト・1,596入力ずつのストリーミング検査に合格。両ツール×両CPUの内蔵バージョン1.2.1を再確認 |

最終署名済みアプリとセキュリティ検査済みツールについて、Mach-Oのファイル上に存在する全sectionをCPU別にSHA-256で比較し、両ツールとも一致した。
署名付加でMach-Oヘッダ・LINKEDIT・fat配置が変わるため、ファイル全体のハッシュ一致とは区別した。
正常/破損BrotliDecode PDFと、日本語5ページのEPS/SVG変換・移設テストも両CPUで再実行して成功した。
CVE固有の攻撃PoCではないという制約は、元のBrotli監査と同じ。

ローカルの詳細ログ・JSON・全80件のMarkdown結果は `build/comprehensive-2026-10-25/` に保存した（Git管理外）。
変換生成物の所在は同ディレクトリの `root.txt` に記録。
最終署名済みReleaseアプリは `/tmp/tex2img-deps.Zplgm3/TeX2img-comprehensive.app`。

## 本機で残る問題・検証範囲

### PDFKitの保存処理

通常80ケースの仕様検査だけでは、PDF構造の厳密な正しさまで保証できない。
追加のqpdfおよびMuPDFでの検査で次を検出した。

- 各CPUのPDF60ファイル中14ファイルで、qpdfがxrefの `object has offset 0` を警告（終了コード3）。
- 各CPUのPDF60ファイル中4ファイル（10の8ページ目、12の8ページ目、13・15の結合PDF）で、MuPDFが `cannot find ExtGState resource 'N'` を報告し、画像は出力するが終了コード1。
- qpdfの警告は、元PDFの7ページ目をPDFKitだけで別PDFへ保存する最小コードでも再現した。
- ExtGState問題は、元PDFの8ページ目をGhostscriptでアウトライン化した時点では発生せず、そのPDFをPDFKitだけで再保存すると発生した。TeX2imgおよび更新したライブラリを使わない再保存処理で切り分けた。
- 既知のpgfplotsメッシュ問題も両CPUで再現。入力のShadingType 4が1,521個、PatternType 1が0個に対し、出力はそれぞれ0個・1,521個。既存方針どおり別枠の保留扱い。

今回SVG経路の背景合成順序は修正したが、PDF出力の保存・ページ結合全般をPDFKitから置き換える修正は行っていない。
これらは「すべての生成PDFが警告なく正常」とは判定できない残存事項である。

### 本機のTeX環境

GUIの既定pLaTeXで数式をコンパイルすると、`negmedspace` / `negthickspace` の再定義、`l3backend-dvipdfmx.def` の欠落により失敗した。
同梱変換ライブラリに到達する前の外部TeX環境の問題。
パッケージに依存しないplain pdfTeX入力で、CLIのTeXコンパイル→PDF変換経路は両CPUとも確認した。
GUIではPDF→EPS/SVG、修正版のPS→SVGを実行し、生成物を確認した。

本機の `/usr/local/tetex/bin/gs` ラッパーは末尾が引用なしの `$@` であり、直接スペース入りファイル名を渡すと引数が分割される。
追加のEPS全ファイル検査では、`gs-noX11` に `GS_LIB` を明示して実行した。
本機のTeX/Ghostscriptインストール自体には変更を加えていない。

### OS下限

Releaseアプリの9 Mach-O、同梱変換ツールの両スライス、署名・動的依存を再検査。
最低OSは12.0のまま。macOS 12実機/VMおよびIntel実機での実行確認は本機ではできていない。

## Ghostscript更新後の追試

その後、ラッパー修正とGhostscript 10.07.1がインストールされた。
[更新後の実機検証](ghostscript-10.07.1-2026-10-25.md)を参照。
上記のラッパーの引数分割問題は、この追試では解消を確認した。

## PDFKit問題の追調査

その後の[保存経路の追調査](pdfkit-preservation-2026-10-25.md)で、元の文書を保存する場合と新規文書へページを挿入する場合の違いを確認した。
ページ構成を変えないクロップを修正し、単一ページ・透過出力のメッシュ保持を改善した。
本報告の検査結果は、この追加修正前の記録である。
