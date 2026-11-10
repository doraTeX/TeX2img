# エンジン検出

2026-11-07。参照実装: TeXShop `master` (d64473f) の
`TSEnginePathDiscovery`。
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

色設定は[設定ウインドウとカラーテーマ](settings-and-themes.md)を参照。

## 回帰テスト

リポジトリ直下で実行:

```sh
swiftc Sources/Controllers/ControllerG-Extension.swift \
  tests/EngineDiscoveryRegression.swift -o /tmp/tex2img-engine-tests
/tmp/tex2img-engine-tests
```

実行可否、順位、リンク重複、PATH、時間・出力上限、UTF-8不正、TeX Live年度を確認する。

署名なしDebugとReleaseのビルドを検証する。Releaseの増分ビルドではSwiftの
特殊化シンボルが欠落するリンクエラーが出たため、Releaseは `clean build` を使用する。
ユーザーの実エンジンを使ったアプリ全体の手動操作確認は別途必要。
