# Swift Migration Notes

Objective-C から Swift への全面移植作業の進捗と、後で現代化すべき obsolete API の記録。

## 進捗

| クラス / ファイル | 状態 | コミット |
|---|---|---|
| NSArray-Extension | 完了 | swift-migration 初回コミット |
| NSDictionary-Extension | 完了 | 2番目のコミット |
| NSMutableString-Extension | 完了 | 3番目のコミット |
| NSString-Extension | 完了 | 4番目のコミット |
| NSString-Conversion | 未着手 | — |
| NSString-Unicode | 完了 | Migrate NSString-Unicode from Objective-C to Swift |
| Utility | 完了 | 5番目のコミット |
| UtilityG | 完了 | Migrate UtilityG from Objective-C to Swift |
| UtilityC | 完了 | 6番目のコミット |
| Converter | 未着手（BoundingBox 部分は Swift 済） | — |
| ControllerG | 未着手（Extension 部分は Swift 済） | — |
| ControllerC | 完了 | Migrate ControllerC from Objective-C to Swift |
| ProfileController | 未着手 | — |
| MyGlyphPopoverController | 未着手 | — |
| TeXTextView | 未着手（Bullet 部分は Swift 済） | — |
| main.m | 未着手 | — |
| mainc.m | 完了（mainc.swift + Argument Parser） | Migrate mainc to Swift Argument Parser |

## Obsolete API（Swift 化完了後に現代化）

- `Utility.execCommand` — `Process` で `/bin/bash -c` を実行している。呼び出し元がシェル文字列を渡す API のため現状維持。引数配列を直接渡す形へのリファクタリングが必要。
- `ControllerG-Extension.searchProgram` — 同様に `bash -c` を使用（未移植）。

## mainc 移植メモ

- `mainc.m`（getopt_long）を `mainc.swift`（Swift Argument Parser）へ全面移行。
- getopt のオプション最短マッチ（prefix abbreviation）は再現しない。フルオプション名（または定義した短縮形）が必要。
- シノニムオプション（`--compiler` / `--latex`、`--dviware` / `--dvidriver` / `--dvipdfmx`）は Argument Parser の複数名で維持。
- `--[no-]xxx` 形式のフラグは正/負ペアの `@Flag` で実装。両方指定時はコマンドライン上の後勝ち。
- バージョン文字列は `let tex2imgVersion`（deployc.sh のシェルスクリプトも参照先を更新）。
- tex2img ターゲットに Swift Argument Parser（SPM）を追加。
- `Bridging-Header-C.h` に `global.h` を追加（Profile キー定数の利用）。

## UtilityC 移植メモ

- `checkWhich` / `getPath` — 旧実装の `system()` / `popen()` + シェル経由の `which` を，`Process` で `/usr/bin/which` を直接実行する形に変更。PATH は `Process.environment` で設定。
- `printStdErr` — C の可変長引数から `[UtilityC printStdErr:]`（`NSString` 受け取り）に変更。