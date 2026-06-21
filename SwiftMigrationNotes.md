# Swift Migration Notes

Objective-C から Swift への全面移植作業の進捗と、後で現代化すべき obsolete API の記録。

## 進捗

| クラス / ファイル | 状態 | コミット |
|---|---|---|
| NSArray-Extension | 完了 | swift-migration 初回コミット |
| NSDictionary-Extension | 完了 | 2番目のコミット |
| NSMutableString-Extension | 完了 | 3番目のコミット |
| NSString-Extension | 完了 | 4番目のコミット |
| NSString-Conversion | 完了 | Migrate NSString-Conversion from Objective-C to Swift |
| NSString-Unicode | 完了 | Migrate NSString-Unicode from Objective-C to Swift |
| Utility | 完了 | 5番目のコミット |
| UtilityG | 完了 | Migrate UtilityG from Objective-C to Swift |
| UtilityC | 完了 | 6番目のコミット |
| Converter | 完了 | Migrate Converter from Objective-C to Swift |
| ControllerG | 完了 | Migrate ControllerG from Objective-C to Swift |
| ControllerC | 完了 | Migrate ControllerC from Objective-C to Swift |
| ProfileController | 完了 | Migrate ProfileController from Objective-C to Swift |
| MyGlyphPopoverController | 完了 | Migrate MyGlyphPopoverController from Objective-C to Swift |
| TeXTextView | 完了 | Migrate TeXTextView from Objective-C to Swift |
| main.m | 完了（削除、AppDelegate @main） | Remove main.m and use @main AppDelegate entry point |
| mainc.m | 完了（mainc.swift + Argument Parser） | Migrate mainc to Swift Argument Parser |

### 意図的に残存する Objective-C / C ヘッダ

- `Sources/global.h` — マクロ・定数
- `Sources/typedef.h` — `ExitStatus`, `Profile` 型など
- `Sources/UtilityG.h` — `localizedString` マクロのみ
- `Sources/Bridging-Header-C.h`, `Sources/Bridging-Header-G.h`
- `Sources/icu/*.h` — ICU C API ヘッダ

## 安全ビルド手順

Dropbox 上のプロジェクトで `xcodebuild` を並列実行すると WindowServer フリーズ（ウォッチドッグ・パニック）の原因になる。以下を守ること。

```bash
# Dropbox 同期を一時停止してから実行
./scripts/safe-build.sh tex2img    # CUI のみ
./scripts/safe-build.sh TeX2img    # GUI（tex2img 依存を含む）
./scripts/safe-build.sh all        # 両方
```

- DerivedData は `~/Developer/DerivedData/TeX2img`（Dropbox 外）
- 並列度 `-jobs 1`
- プロジェクト内の `build/` は使わない（`.gitignore` 済み）

### マルチターゲットビルド修正

TeX2img と tex2img が Swift ソースを共有しているため、Xcode が `GeneratedAssetSymbols.swift` を tex2img 側に誤って含める問題があった。対策:

- TeX2img に `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOLS = NO`
- tex2img に `SWIFT_EMIT_CONST_VALUES = NO`
- TeX2img → tex2img の `PBXTargetDependency` を追加

## Obsolete API（Swift 化完了後に現代化）

- `Utility.execCommand` — `Process` で `/bin/bash -c` を実行している。呼び出し元がシェル文字列を渡す API のため現状維持。引数配列を直接渡す形へのリファクタリングが必要。
- `ControllerG-Extension.searchProgram` — 同様に `bash -c` を使用。

## mainc 移植メモ

- `mainc.m`（getopt_long）を `mainc.swift`（Swift Argument Parser）へ全面移行。
- getopt のオプション最短マッチ（prefix abbreviation）は再現しない。フルオプション名（または定義した短縮形）が必要。
- シノニムオプション（`--compiler` / `--latex`、`--dviware` / `--dvidriver` / `--dvipdfmx`）は Argument Parser の複数名で維持。
- `--[no-]xxx` 形式のフラグは正/負ペアの `@Flag` で実装。両方指定時はコマンドライン上の後勝ち。
- バージョン文字列は `let tex2imgVersion`（deployc.sh のシェルスクリプトも参照先を更新）。
- tex2img ターゲットに Swift Argument Parser（SPM）を追加。
- `Bridging-Header-C.h` に `global.h` を追加（Profile キー定数の利用）。

## NSString-Conversion 移植メモ

- 旧 `NSString-Conversion.m` の約 15,465 件の `replaceCID:withUnicodePoint:` 呼び出しを `[Int: UInt32]` 辞書 `cidToUnicode` に集約。
- `NSString-Conversion+CIDTable.swift`（`scripts/generate_cid_table.py` で生成）、`+LigTable.swift`（`scripts/extract_lig_pairs.py`）に分割。
- コンパイル負荷が大きい。将来的には実行時ロード（plist/JSON）への移行を検討。

## UtilityC 移植メモ

- `checkWhich` / `getPath` — 旧実装の `system()` / `popen()` + シェル経由の `which` を，`Process` で `/usr/bin/which` を直接実行する形に変更。PATH は `Process.environment` で設定。
- `printStdErr` — C の可変長引数から `[UtilityC printStdErr:]`（`NSString` 受け取り）に変更。

## 残作業（Swift 化完了後）

- 不要な `@objc` 修飾子の整理（XIB 接続に必要な分のみ残す）
- `ObjCBool` 残存チェック
- obsolete API の現代化（上記セクション参照）
- `NSString-Conversion+CIDTable.swift` の実行時ロード化（ビルド負荷軽減）