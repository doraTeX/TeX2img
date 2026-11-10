# エンジン検出とTeXShopの色設定

2026-11-07。参照実装: TeXShop `master` (d64473f) の
`TSEnginePathDiscovery`、`TSColorSupport`、テーマ設定キー。
TeXShopの作業ツリーや設定ファイルは変更しない。

## エンジンパス

初回の設定と既存の自動設定ボタンで、選択テンプレートのLaTeX、DVIドライバ、
Ghostscriptをバックグラウンド検索し、バージョンとパスを候補メニューに表示する。
TeX Liveの年、バージョン番号の数値比較順で新しいものを初期選択する。
正常終了するがバージョンが不明な候補も末尾に残す。

- `/etc/paths`、`/etc/paths.d`、環境変数PATH、既知のインストール先を検索。
- TeX Liveは実在する年度ディレクトリを列挙。universal/arm64にも対応。
- 空・相対PATHを除外し、実行可能ファイルだけを対象とする。
- シンボリックリンクの実体で重複を除外。同一実体ならMacTeXの安定パスを優先。
- `--version` はシェルを介さず実行。1件2秒・出力64KiBまで。
- 未検出の項目は既存設定を保持。キャンセルではパスとテンプレートを変更しない。
- 検索後に設定値・テンプレートが変わった場合、設定画面を閉じた場合、
  プロファイルを切り替えた場合、または再検索した場合は古い結果を適用しない。
- DVIドライバの `-vv` / `-Ppdf` は従来どおり付与する。

## 色設定

現行Swift版にはTeXShop色設定の読込処理がなかったため、色設定の
「デフォルト」ボタンの左に「TeXShopから読み込む…」メニューを追加した。
ライト／ダークを選択し、確認後、そのモードだけを読み込む。
既存のデフォルト復元操作は変更しない。

`TeXShop` preferences domainの `DefaultLiteTheme` / `DefaultDarkTheme` を参照し、
`~/Library/TeXShop/Themes` の選択テーマを読む。テーマを読めない場合は
`LiteTheme.plist` / `DarkTheme.plist` を試す。

文字・背景・カーソル、コメント・コマンド・中括弧、不可視文字、括弧強調・
内容強調・フラッシュ、コンソール文字・背景をTeX2imgの対応する色へ取り込む。
TeX2imgには丸括弧・角括弧を個別に色分けする設定がないため、これらは追加しない。

中括弧は `SyntaxMarkerCurly` を優先し、キーがない場合だけ `SyntaxMarker` を使う。
さらにテーマの該当キーがない場合、対応する旧preferencesのRGB設定があれば使用する。
新キーが存在するが壊れている場合は旧値に置換せず、その項目のTeX2imgの色を保持する。
不足した配列、不正な数値・範囲外の色も適用しない。

## 回帰テスト

リポジトリ直下で実行:

```sh
swiftc Sources/Controllers/ControllerG-Extension.swift \
  Sources/Extensions/AppKit/NSColor-Extension.swift \
  tests/EngineAndThemeRegression.swift -o /tmp/tex2img-engine-theme-tests
/tmp/tex2img-engine-theme-tests
python3 tests/test_texshop_color_controls.py
```

実行可否、順位、リンク重複、PATH、時間・出力上限、UTF-8不正、TeX Live年度、
新旧色キー優先順位、破損値、テーマ選択・既定テーマフォールバックを確認する。
色読み込みメニューは実際の生成メソッドをAppKitで実行し、日英レイアウトで
二重生成・既存ボタンとの重なりがなく、非選択タブにも設置されることを確認する。

署名なしDebugとReleaseのビルドを検証する。Releaseの増分ビルドではSwiftの
特殊化シンボルが欠落するリンクエラーが出たため、Releaseは `clean build` を使用する。
ユーザーの実テーマ・実エンジンを使ったアプリ全体の手動操作確認は別途必要。
