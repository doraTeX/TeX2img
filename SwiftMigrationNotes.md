# Swift Migration Notes

Objective-C から Swift への全面移植作業の進捗と、後で現代化すべき obsolete API の記録。

## 進捗

| クラス / ファイル | 状態 | コミット |
|---|---|---|
| NSArray-Extension | 完了 | swift-migration 初回コミット |
| NSDictionary-Extension | 完了 | 2番目のコミット |
| NSMutableString-Extension | 完了 | 3番目のコミット |
| NSString-Extension | 未着手 | — |
| NSString-Conversion | 未着手 | — |
| NSString-Unicode | 未着手 | — |
| Utility | 未着手 | — |
| UtilityG | 未着手 | — |
| UtilityC | 未着手 | — |
| Converter | 未着手（BoundingBox 部分は Swift 済） | — |
| ControllerG | 未着手（Extension 部分は Swift 済） | — |
| ControllerC | 未着手 | — |
| ProfileController | 未着手 | — |
| MyGlyphPopoverController | 未着手 | — |
| TeXTextView | 未着手（Bullet 部分は Swift 済） | — |
| main.m | 未着手 | — |
| mainc.m | 未着手（Argument Parser へ移行予定） | — |

## Obsolete API（Swift 化完了後に現代化）

（まだ記録なし）