# 同梱ライブラリ更新・検証記録（2026-10-25）

対象: [Issue #128](https://github.com/doraTeX/TeX2img/issues/128)。作業はローカルのみ。配布、push、Issueへの投稿はしていない。

## 更新した構成

| 構成要素 | 更新後 |
|---|---|
| Poppler / pdftops | 26.10.0（旧20.09.0） |
| MuPDF / mudraw | 1.28.5（旧1.17.0）。公式mutoolのargv[0]=mudraw互換呼び出しを利用 |
| Brotli | 1.2.1（両CPU・両ツール共通） |
| FreeType | 2.15.0 |
| Fontconfig | 2.18.3 |
| Expat | 2.9.0 |
| libpng | 1.6.59 |
| libjpeg-turbo | 3.2.0 |
| OpenJPEG | 2.5.4 |
| Little CMS | 2.19.1 |
| zlib | 1.3.2 |
| poppler-data | 0.4.12（CMap等を新たに同梱） |
| epstopdf | 2.36（旧2.30） |
| Swift Argument Parser | 最新安定版1.8.2をXcodeで固定 |
| Sparkle | 2.10.0が最新安定版のため維持。配布用ツールも同版 |

MuPDF内部のJBIG2デコーダは最新版0.20系を含むMuPDF公式リリースのソースを使用する。
内蔵フォントとMuPDF固有コードも1.28.5配布物のもの。macOS提供のICU・libc++等はOSのライブラリを使用し、独自版を同梱しない。

上流の配布物とハッシュは `ThirdParty/bundled-sources.json`、実際のバイナリとBrotli静的ライブラリのハッシュは `Resources/pdftops/build-info.json` に記録。
ライセンスは `Resources/pdftops/licenses/` と `Resources/mupdf/MuPDF.license`、epstopdf自身のヘッダに含む。
ソースの再取得とビルド手順は `scripts/build-bundled-tools.py` に固定してある。

公式の最新版確認先:

- [Poppler](https://poppler.freedesktop.org/)、[MuPDF](https://mupdf.com/releases)
- [Brotli 1.2.1](https://github.com/google/brotli/releases/tag/v1.2.1)、[FreeType](https://freetype.org/index.html)、[libpng](https://www.libpng.org/pub/png/libpng.html)
- その他のソースURLは上記マニフェスト参照。GitHubでリリースを持つ依存はRelease APIでも確認した。
- [Sparkle 2.10.0](https://github.com/sparkle-project/Sparkle/releases/tag/2.10.0)、[Swift Argument Parser 1.8.2](https://github.com/apple/swift-argument-parser/releases/tag/1.8.2)

## CVE-2026-111497の確認

Google公式1.2.1のソースをSHA-256固定で取得した。
修正コミットは [`b418fa81c48262a86a95332b0bc6d62c30aa78b6`](https://github.com/google/brotli/commit/b418fa81c48262a86a95332b0bc6d62c30aa78b6)、
リリースのコミットは `db24a98aed38a16de78cc05ca15cdd8dc2a0d92d`。

修正は、不正なblock switchを `BROTLI_DECODER_ERROR_FORMAT_BLOCK_SWITCH`（-17）として検出し、literal / command / distanceの切替と上位ループに伝播させ、処理を止めるもの。
旧コードの「入力不足」との混同や高速経路での戻り値無視を解消している。

確認した証拠:

1. ハッシュ固定したアーカイブの `c/` 配下とテスト対象ソースの全バイトが一致することを検査。
2. Google同梱の互換性・roundtripテスト12件を、arm64とx86_64でそれぞれ全件通過。
3. `tests/brotli/block-switch.c` で3種類の切替、通常/安全経路、上位command処理までのエラー伝播を確認。両CPUともAddressSanitizerとUndefinedBehaviorSanitizerを有効にして通過。
4. 同テストを旧1.2.0ソースで実行すると、不正切替のエラー判定で期待どおり失敗することを確認（対照実験）。
5. 公開ストリーミングAPIに、正常な公式圧縮データ・切り詰め・bit反転を入力。各CPUで1,596ケースをASan/UBSan下で通過。
6. **実際の同梱pdftops / mudraw × arm64 / x86_64の4スライス**を逆アセンブルし、`BrotliDecoderVersion` が全て `0x01002001`（1.2.1）を返すことを確認。MuPDFではこの関数がdead-stripされないよう明示的に保持。
7. 2ツールはビルドした1.2.1の静的ライブラリをリンク。リンクマップは作業ディレクトリの各CPUの `poppler/link.map` と `mupdf/link.map` に出力する。MuPDF公式配布物内の旧Brotliはコンパイルに使わない。
8. CLIが `/Applications` 等の旧TeX2imgを自身の同梱ツールより優先する経路を修正。実行ファイルをシンボリックリンクから起動した場合も自身の配布物を選ぶ。GUIは元から自身のBundleを参照。
9. 旧 `pdftops-lib` のdylib群を削除。新しい2実行ファイルの動的依存はmacOSのシステムライブラリだけであり、旧Brotliを動的ロードしない。
10. BrotliDecodeフィルタで本文を圧縮したPDFを、実際の両ツール・両CPUで正常変換。破損Brotliストリームを持つPDFでもクラッシュ/タイムアウトしないことを確認。

上流の1.2.0→1.2.1差分にはCVE専用の入力fixtureが含まれていない。
このため、3のテストは修正条件を作る内部状態の回帰テストであり、実際の攻撃PDFのPoC再現と同一ではない。
10の破損ストリームも一般的な異常入力テストであり、このCVEを発火させる入力とは主張しない。
これらの範囲を区別したうえで、**修正済みソースを両CPU・両ツールへ組み込んだことと修正の挙動**を確認した。

## OS要件とUniversal Binary

本体の `MACOSX_DEPLOYMENT_TARGET` はGUI/CLIとも12.0のまま。
全ての新規C/C++依存を両CPU向けに `-mmacosx-version-min=12.0` でソースビルドした。
最低OSのMach-O表示を後から書き換える旧処理は廃止した。

- pdftops / mudraw: arm64 + x86_64、両スライスのminOS=12.0。
- Release GUI/CLI、SparkleおよびUpdater/Installer/Downloader等を含む9 Mach-Oを検査し、両CPUと最低OS≦12.0を確認。
- システム以外の絶対パスや未解決dylib依存も検査。
- CMakeでビルドするC/C++依存とMuPDFでは、unguarded availabilityの警告をエラー化。
- FreeType 2.15で追加されたApple HVFフォント対応を無効化し、新OSの `libhvf` 依存を回避。従来のTeX用Type1/TrueType/OpenType等は維持。
- Intel側だけ/arm64側だけ最低OS=13にした実バイナリ、thin、存在しないファイルを検査ツールが拒否することもテスト。

**今回の構成では本体の最低要件を12.0から引き上げる必要は認められなかった。**
ただし、実行テストは現行macOSのApple Silicon機で実施し、x86_64はRosettaを使用した。
macOS 12実機/VM・Intel実機での実行確認はしていない。最低OS実機の確認は配布前の追加検証として残る。

## 構成上の変更と変換確認

変換に必要なライブラリを静的リンクし、以前のCPUごとに版が違うdylibの結合・ABI名の付け替えを廃止。
古いOpenSSL、NSS/NSPR、curlとその依存、TIFF出力用依存等は、使用しないオプション機能とともに同梱から外した。

- Poppler: ローカルPDF→EPSに必要なJPEG/JPX、色管理、FreeType、Fontconfig、Brotliを有効化。通信、署名検証、追加フロントエンド、TIFF出力、HarfBuzzによるフォントサブセット生成は無効。
- MuPDF: PDF→SVGを含む描画機能を維持。HTML/EPUB等のエンジン、JavaScript、DOCX抽出、GUI、通信、暗号署名バックエンドは無効。TeX2imgがこれらを使う経路はない。PDF暗号化の読み取り機能とは別の設定。
- フォント検索はユーザーが `FONTCONFIG_FILE` / `FONTCONFIG_PATH` を指定すれば尊重し、未指定ならmacOS標準フォントディレクトリを使用。
- poppler-dataを実行ファイルからの相対位置で参照。ビルド機の `/opt/local/share/poppler` 等に依存しない。
- スペースを含む別ディレクトリへツール一式をコピーした状態で、日本語サンプルの非空5ページを両CPUでEPS/SVGに変換し、CMap不足・未知のフォント・構文エラーがないことを確認。

ビルド・検証コマンドは[ビルド手順](../build-and-deploy.md#6-同梱pdf変換ツールの更新)を参照。

追加のアプリ検証:

- GUI/CLI両方のReleaseビルド成功。署名済みアプリ全体の `codesign --verify --deep --strict` 成功。
- 同梱CLIをarm64/x86_64として実行し、日本語PDFからEPS/SVG/PDF/PNGへ変換（テキスト付きSVGも含め10件）成功。各実行ログでpdftops・mudraw・epstopdfが全て検査対象アプリ内の絶対パスを指すことを確認。テキスト付きSVGは日本語のdata-textも照合。
- EPSをGhostscriptで描画し、日本語「こんにちは」が欠けずに出力されることも目視確認。
- Dropbox配下の生成物には同期時の拡張属性が付くため、署名確認と実行確認は `ditto --norsrc --noextattr` でローカル一時ディレクトリへコピーしたアプリで行った。

## 全件検査後の追加記録

既存80ケース×両CPU、GUI、入力形式、生成物の構造検査を追加実施した。
検査中のSVG・PS/EPS修正と、残存するPDFKitの構造警告・メッシュ問題については
[本機での網羅テスト報告](comprehensive-tests-2026-10-25.md)を参照。
