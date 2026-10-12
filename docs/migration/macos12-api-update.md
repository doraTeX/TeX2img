# macOS 12向け非推奨API対応

2026-10-12実施。GUI・CLIとも最低OSはmacOS 12.0を維持する。

## 変更

- ファイル選択／保存パネルは`allowedContentTypes`へ移行。TeX・圧縮SVGを含む従来の11拡張子を保持し、保存形式の変更時は選択形式を先頭へ移す。
- 画像形式識別子を`UTType`へ移行。JPEG・PNG・TIFF・GIFのImageIOに渡す識別子は従来と同じ。
- CLIの3桁／6桁の16進背景色指定を`UInt32(_:radix:)`へ移行。
- プロファイル並べ替えのドラッグデータはsecure codingを使い、`NSIndexSet`に限定して復元。旧形式のデータも読み込み可能。
- 通知は旧OS向け分岐を削除し、前面表示を`.banner`／`.list`へ移行。無音の通知は維持。初回の通知許可完了後に登録し、失敗はメインスレッドで処理される既存ログ経路へ送る。
- Finderでフォルダを開く処理を`NSWorkspace.open(_:withApplicationAt:configuration:completionHandler:)`へ移行。

## 検証

- GUI／CLI × Debug／Releaseの4構成でビルド成功。deprecated警告はゼロ。
- GUIにはXcode自身の「AppIntents未使用のためメタデータ抽出を省略」の警告が残る。APIの非推奨警告ではなく、警告抑制設定は追加していない。
- `tests/test_modern_api_compatibility.py`成功。実際のCLI色解析12ケース、11拡張子、新旧のドラッグデータを確認。
- 既存の変換検証スクリプトを一時ディレクトリで実行。テスト37・40・41・44・45・49・56・57・64の9件が成功。PNG／JPEG／BMP／TIFF／GIF、背景色、透過、余白、複数ページTIFF、アニメーションGIFの出力内容を確認。
- テスト実行OSは手元のmacOS。macOS 12実機での検証は行っていない。

## 保存形式切り替えの追加修正

GUIの保存パネルでSVGZを選んでもファイル名が`.eps`のままになることを確認。アクセサリの`sender.window`を`NSSavePanel`へキャストせず、表示中の保存パネルへのweak参照を使うように修正した。

`tests/test_save_panel_format.py`は実際の形式変更メソッドをAppKit上で実行し、ポップアップが別ウインドウにある条件で9形式の保存名・許可形式を検証する。テスト成功。修正後のGUI Debug／Releaseビルドも成功。GUI操作ツールの再起動タイムアウトにより、修正後の実画面での再操作は未確認。
