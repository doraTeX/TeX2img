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

### 残存ヘッダ（必要なもののみ）

| ファイル | 理由 |
|---|---|
| `Sources/Bridging-Header-G.h` | ICU C API（`NSString-Unicode.swift`）用 |
| `Sources/Bridging-Header-C.h` | 空（将来の C ブリッジ用プレースホルダ） |
| `Sources/icu/*.h` | ICU ライブラリの公式 C ヘッダ |

削除済み: `global.h`, `typedef.h`, `UtilityG.h`, `TeX2img_Prefix.pch`  
→ `GlobalConstants.swift`, `Types.swift` に移行

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

## Obsolete API 現代化（完了）

| API | 変更内容 |
|---|---|
| `Utility.execCommand` | `/bin/bash -c` → 実行ファイルパス + 引数配列を直接 `Process` に渡す形へ |
| `ControllerC.execCommand` | `/bin/sh -c` → `ControllerG` と同様に実行ファイルを直接起動 |
| `ControllerG-Extension.searchProgram` | `bash -c` + `path_helper` → `/usr/libexec/path_helper` を直接実行し PATH をパース |
| `ObjCBool` | `FileManager.isDirectory(atPath:)` / `isRegularFile(atPath:)`（`URLResourceValues` ベース）へ置換 |

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
- CID テーブルは `Resources/cidToUnicode.json`（15,464 件）としてバンドルし、実行時に JSON ロード（`NSString-Conversion+CIDTable.swift` はローダーのみ）。tex2img CLI は CID 変換を使わないため空辞書で動作。

## UtilityC 移植メモ

- `checkWhich` / `getPath` — 旧実装の `system()` / `popen()` + シェル経由の `which` を，`Process` で `/usr/bin/which` を直接実行する形に変更。PATH は `Process.environment` で設定。
- `printStdErr` — C の可変長引数から `[UtilityC printStdErr:]`（`NSString` 受け取り）に変更。

## 残作業（Swift 化完了後）

### 完了

- `ObjCBool` 除去 → `FileManager.isDirectory(atPath:)` / `isRegularFile(atPath:)`
- obsolete API 現代化（`execCommand`, `searchProgram`）
- `NSString-Conversion+CIDTable.swift` の実行時ロード化（`Resources/cidToUnicode.json`）
- 一部 `@objc` 整理（`NSString-Conversion` 全メソッド、`Converter` プロパティ、`searchProgram`）

### OutputController pure Swift 化（完了）

- `@objc protocol OutputController` → `protocol OutputController: AnyObject`
- `DnDDelegate` も同様に pure Swift 化
- `ExitStatus` から `@objc` を除去
- ControllerG の `performSelector(onMainThread:)` → `DispatchQueue.main.sync/async`（`performOnMainThread` ヘルパー経由）
- ControllerC / ControllerG の OutputController 実装から `@objc` を除去

### `@objc` 整理（完了）

不要な `@objc` をすべて削除。**Swift ソース上の明示的 `@objc` は 0 箇所**。

主な変更（コミット `4557d8a`）:

| 変更前 | 変更後 |
|---|---|
| XIB `customClass` のみ | `customModule="TeX2img"` 追加 → クラスレベル `@objc` 削除 |
| `NotificationCenter.addObserver(selector:)` | `addObserver(forName:queue:using:)` + token 保持 |
| `Thread.detachNewThreadSelector(compileAndConvert...)` | `DispatchQueue.global().async` |
| `performSelector(onMainThread:runAppleScript...)` | `DispatchQueue.main.async` |
| `Selector("textViewDidChangeSelection:")` | `TeXTextView` 内の block observer + `refreshSelectionHighlighting()` |
| `@objc dynamic` on MyGlyphPopoverController | XIB バインディング廃止 → `loadView()` で IBOutlet 更新 |

`#selector` / `@IBAction` は AppKit の動的メニュー・ボタンアクション用に残るが、これらは暗黙の ObjC 露出であり明示的 `@objc` 注釈ではない。

### 小さめの現代化（完了）

| 項目 | 変更内容 |
|---|---|
| `NSTemporaryDirectory()` | `FileManager.default.temporaryDirectory.path`（`ControllerG` 7 箇所） |
| GlyphPopover XIB バインディング | IBOutlet + `updateFields()` に置換、`@objc dynamic` 除去 |

### 型の現代化（完了）

| 変更 | 状態 |
|---|---|
| `String-Extension.swift`（パス操作・`quotingWithDoubleQuotations` 等） | 完了 |
| `Dictionary where Key == String` に profile 読み取り API | 完了 |
| `[Bool].indexesOfTrueValue()` / `trueValueCount` | 完了 |
| `Converter` の `emptyPageFlags` / `whitePageFlags` → `[Bool]` | 完了 |
| ページ警告 API → `[Int]`（`[NSNumber]` 廃止） | 完了 |
| `commandCompletionList` → `String?` | 完了 |
| `Converter` / `ControllerG` / `mainc` の `as NSString` パス操作 | 完了 |
| `typealias Profile = [String: Any]`（`NSDictionary` / `NSMutableDictionary` 廃止） | 完了 |
| `NSDictionary-Extension` の ObjC 版削除 | 完了 |
| `NSArray-Extension` の ObjC 版削除（`[Bool]` 版のみ残存） | 完了 |
| `NSString-Conversion` 公開 API → `extension String` | 完了（内部は `NSMutableString` バッファ） |
| `String-Extension` に NSRange ヘルパー追加 | 完了 |
| `TeXTextView` の `string as NSString` 置換 | 完了 |

残存する `NSString` 利用（意図的に残す）:

| 箇所 | 理由 |
|---|---|
| `NSString-Unicode.swift` | ICU C API ブリッジ |
| `NSMutableString-Extension.swift` | インプレース置換ヘルパー（`NSString-Conversion` 内部） |
| `MyGlyphPopoverController.swift` | `unicodeName()` / `localizedBlockName()` 等の NSString 拡張 |
| `ControllerG` の AppleScript 認証 delegate | `AutoreleasingUnsafeMutablePointer<NSString?>` API 要件 |
| `String-Extension` 内部 | `(self as NSString)` による AppKit/Foundation ブリッジ |