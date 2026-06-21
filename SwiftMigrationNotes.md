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

### `@objc` 整理（完了）

不要な `@objc` を削除。残存は以下の理由によるもののみ:

| 残存箇所 | 理由 |
|---|---|
| `@objc(ControllerG)` / `@objc(TeXTextView)` / `@objc(ProfileController)` / `@objc(MyGlyphPopoverController)` / `@objc(Converter)` | XIB の `customClass` 接続 |
| `@objc protocol OutputController` + 実装メソッド（ControllerG/C） | バックグラウンドスレッドからの動的ディスパッチ |
| `performSelector` / `NSNotification` オブザーバターゲット | セレクタベースの呼び出し |
| `@objc(compileAndConvertWith*)` on Converter | `Thread.detachNewThreadSelector` |
| `@objc dynamic` on MyGlyphPopoverController | XIB バインディング |
| `@objc enum ExitStatus` / `@objc protocol DnDDelegate` | OutputController / DnD 連携 |
| `TeXTextView.textViewDidChangeSelection` | `Selector("textViewDidChangeSelection:")` 経由の通知 |

削除済み: 全 Foundation/AppKit/PDF/NSString 拡張、Utility/UtilityC/UtilityG、Converter 初期化子・BBox ヘルパー、ControllerG のプロファイル/文字表示 API 等（約 120 箇所）