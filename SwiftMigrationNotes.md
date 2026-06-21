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
| NSString-Unicode | 未着手 | — |
| Utility | 完了 | 5番目のコミット |
| UtilityG | 未着手 | — |
| UtilityC | 完了 | 6番目のコミット |
| Converter | 未着手（BoundingBox 部分は Swift 済） | — |
| ControllerG | 未着手（Extension 部分は Swift 済） | — |
| ControllerC | 未着手 | — |
| ProfileController | 未着手 | — |
| MyGlyphPopoverController | 未着手 | — |
| TeXTextView | 未着手（Bullet 部分は Swift 済） | — |
| main.m | 未着手 | — |
| mainc.m | 未着手（Argument Parser へ移行予定） | — |

## Obsolete API（Swift 化完了後に現代化）

- `Utility.execCommand` — `Process` で `/bin/bash -c` を実行している。呼び出し元がシェル文字列を渡す API のため現状維持。引数配列を直接渡す形へのリファクタリングが必要。
- `ControllerG-Extension.searchProgram` — 同様に `bash -c` を使用（未移植）。

## UtilityC 移植メモ

- `checkWhich` / `getPath` — 旧実装の `system()` / `popen()` + シェル経由の `which` を，`Process` で `/usr/bin/which` を直接実行する形に変更。PATH は `Process.environment` で設定。
- `printStdErr` — C の可変長引数から `[UtilityC printStdErr:]`（`NSString` 受け取り）に変更。