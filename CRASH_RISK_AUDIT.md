# TeX2img クラッシュリスク診断レポート

**作成日**: 2026-06-25  
**対象**: `TeX2img` GUI / `tex2img` CLI の `Sources` 配下  
**目的**: 外から見た動作を変えずに修正可能なクラッシュ要因を、対応前に優先順位付けする  
**実施内容**: Swift ソースの静的診断、強制アンラップ・境界アクセス・並行処理・Process/Pipe・PDF/Image・通知/KVO・Unsafe Pointer の横断確認、GUI/CLI Debug ビルド  

## 結論

通常の入力ファイル、外部ツール出力、保存済み設定から到達し得るクラッシュ経路が複数ある。特に優先度が高いのは次の4系統。

1. 空ページ PDF と不正な BoundingBox による範囲・配列・数値変換クラッシュ
2. `PDFDocument` / `PDFPage` を複数スレッドから共有・変更する処理
3. 画像生成時のサイズ変換と `NSImage` / `NSBitmapImageRep` の強制アンラップ
4. UTF-16 オフセットと Swift の `String.count` の混在、および無防備な `NSString` 境界アクセス

GUI/CLI の Debug ビルドは成功した。以下はコンパイルエラーではなく、実行時条件で表面化する問題である。

---

## 優先度：高

### 1. 0ページ PDF で ClosedRange 生成が即時クラッシュ

**ファイル**: `Sources/Converter/Converter-BoundingBox.swift:238-242`

```swift
let totalPageCount = inputDoc.pageCount
let targetPages = (page==0) ? [Int](1...totalPageCount) : [page]
```

`page == 0` かつ `pageCount == 0` の場合、`1...0` の生成時に「下限が上限を超える ClosedRange」となり、実行時 trap が発生する。

**到達条件**:

- 0ページとして読み込まれる PDF
- 壊れた PDF や、PDFKit がドキュメント自体は生成するがページを復元できない入力
- 全ページクロップ処理

**推奨対応**:

- `totalPageCount > 0` を guard する。
- 指定ページの場合も `1...pageCount` 内か確認する。

---

### 2. BoundingBox 解析が外部ツール出力を強制変換・固定長配列として扱う

**ファイル**: `Sources/Converter/Converter-BoundingBox.swift:181-185`

```swift
let bbox = bbStr
    ...
    .components(separatedBy: .whitespaces)
    .map { CGFloat(Int($0)!) }
let (bboxLx, bboxLy, bboxUx, bboxUy) = (bbox[0], bbox[1], bbox[2], bbox[3])
```

Ghostscript 等の出力に空要素、非整数、項目不足があると、`Int(...)!` または `bbox[0...3]` でクラッシュする。複数スペースやタブでも空文字列が混入し得る。

関連する強制変換:

- `Converter-BoundingBox.swift:122`
- `Converter-BoundingBox.swift:137`
- `Converter-BoundingBox.swift:51-57` の UTF-8 強制アンラップ

**到達条件**:

- 異なる Ghostscript バージョンやロケールによる出力差
- 壊れた PDF/EPS
- ユーザー指定の互換性がない外部コマンド
- BoundingBox に通常外の表記が含まれる場合

**推奨対応**:

- 空白分割は空要素を除外する。
- 要素数を4と確認し、全要素を optional 数値変換する。
- 解析失敗は変換失敗として既存エラー経路へ返す。

---

### 3. PDFKit オブジェクトの並列共有とデータ競合

**ファイル**: `Sources/Converter/Converter-BoundingBox.swift:238-260`

```swift
let inputDoc = PDFDocument(...)
var success = true

DispatchQueue.concurrentPerform(iterations: outputDocs.count) { i in
    let croppedPage = self.cropPage(..., from: inputDoc, ...)
    success = false
    outputDocs[i].append(croppedPage)
}
```

単一の `PDFDocument` を複数スレッドから参照し、取得した `PDFPage` の bounds を変更している。PDFKit オブジェクトのこの使い方にスレッド安全性の保証はない。また `success` は同期なしで複数スレッドから書き換えられ、Swift のデータ競合となる。

**影響**:

- 多ページ PDF の変換中に低頻度クラッシュ
- PDFKit 内部状態の破損
- 成否判定の不定化

**推奨対応**:

- 最初は逐次処理に戻すのが最も安全。
- 並列化を維持するなら、各処理で独立した `PDFDocument` を生成し、共有状態をロックまたは結果配列で集約する。

---

### 4. 画像生成で Optional と数値変換を強制している

**ファイル**:

- `Sources/Converter/Converter.swift:586-600`
- `Sources/Converter/Converter.swift:693-710`

```swift
let size = NSSize(
    width: Int(width * CGFloat(resolutionLevel)) + ...,
    height: Int(height * CGFloat(resolutionLevel)) + ...
)
...
var imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)!
```

PDF の bounds が非有限値、極端な値、または整数範囲外の場合、`CGFloat` から `Int` への変換が trap する。サイズが巨大な場合はメモリ確保失敗や AppKit 内部例外の可能性がある。さらに `tiffRepresentation` と `NSBitmapImageRep` の生成失敗を強制アンラップしている。

**到達条件**:

- 異常な MediaBox/CropBox を持つ PDF
- 高解像度・巨大ページ・大きな余白設定
- メモリ不足
- AppKit が bitmap representation を生成できない画像

**推奨対応**:

- `isFinite`、正値、上限値、`Int` 変換可能範囲を検証する。
- `tiffRepresentation` と `NSBitmapImageRep` は guard し、既存の画像サイズエラーへ接続する。

---

### 5. 保存済みプロファイルの2配列が不整合になると配列境界クラッシュ

**ファイル**: `Sources/Controllers/ProfileController.swift`

該当箇所:

- 22-29行: `profileNames` と `profiles` を独立にロード
- 17-20行: 名前側の index で `profiles[targetIndex]`
- 37-46行: 同じ index を両配列へ適用
- 92-105行: TableView の選択 index で両配列へアクセス
- 152-181行: drag & drop の `IndexSet` を無検証で配列へ適用

UserDefaults の片側だけが欠損・型不一致・旧形式・破損状態になると、配列数が一致しない。その後のプロファイル選択、削除、更新、並べ替えで範囲外アクセスが発生する。

**再現性**: 中。設定移行、Defaults の手動変更、不完全保存で到達可能。

**推奨対応**:

- 読み込み直後に件数を検証し、不整合データを復旧または破棄する。
- index アクセスごとに両配列の範囲を確認する。
- 長期的には名前と Profile を1つの構造体配列として保存する。

---

### 6. `String.character(at:)` と substring が完全に無防備

**ファイル**: `Sources/Extensions/Foundation/String-Extension.swift:97-138`

```swift
func character(at index: Int) -> unichar {
    (self as NSString).character(at: index)
}
```

負値または UTF-16 長以上の index で Objective-C 例外が発生し、通常の Swift `catch` では回収できない。同様に `substring(with:)`, `substring(from:)`, `substring(to:)`, `lineRange(for:)` も無効範囲をそのまま `NSString` に渡す。

主要な使用箇所:

- `TeXTextView-Colorize.swift`
- `TeXTextView.swift`
- `TeXTextView-CommandCompletion.swift`
- `MyATSTypesetter.swift`
- `ControllerG.swift`
- `Converter.swift`

特にエディタでは `NSTextView` の位置は UTF-16 なのに、複数箇所で `String.count` を NSRange 長・選択長・undo 長として使用している。

例:

- `TeXTextView.swift:289`
- `TeXTextView.swift:343-347`
- `TeXTextView.swift:635-636`
- `TeXTextView-CommandCompletion.swift:143-148`
- `TeXTextView-CommandCompletion.swift:175-176`
- `TeXTextView-CommandCompletion.swift:219-240`

絵文字・サロゲートペア・結合文字を含むソースやコマンド補完リストで、位置計算がずれて無効 NSRange を生成し得る。

**推奨対応**:

- UTF-16 offset 用の安全な Optional API を導入する。
- AppKit / Foundation の NSRange と組み合わせる長さは一貫して `utf16.count` または `NSString.length` を使う。
- substring 系は `Range(_:in:)` または境界 guard を通す。

---

### 7. AppDelegate の KVO クロージャが weak IBOutlet を非防御アクセス

**ファイル**: `Sources/App/AppDelegate.swift:5-18`

```swift
private var observer: Any!
@IBOutlet weak var controllerG: ControllerG!

self.observer = NSApp.observe(\.effectiveAppearance) { _, _ in
    self.controllerG.refreshOutputTextView(usingProfile: nil)
}
```

ウィンドウ・controller 解放後や終了処理中に appearance 通知が来ると、weak IUO の強制アンラップでクラッシュする。KVO observation の明示的な invalidate もない。

同様に `openFile` / `openFiles` も controller 接続前または解放後の呼び出しを防御していない。

**推奨対応**:

- `NSKeyValueObservation?` と `[weak self]` + optional chain を使う。
- 終了時または deinit で invalidate する。

---

### 8. safe subscript の直後を強制アンラップ

**ファイル**: `Sources/Editor/MyLayoutManager.swift:50-53`

```swift
let theCharIndex = characterIndexForGlyph(at: theGlyphIndex)
let theCharacter = theCompleteStr.utf16[safe: theCharIndex]!
```

glyph-to-character 変換が文字列終端や編集中のレイアウトと一致しない場合、`safe` が `nil` を返してクラッシュする。

さらに safe subscript 自体も負の offset を明示的に拒否していない。

**ファイル**: `Sources/Extensions/Foundation/BidirectionalCollection.swift:3-7`

**推奨対応**:

- `guard let` で該当 glyph の追加描画だけをスキップする。
- safe subscript に `offset >= 0 && offset < count` を明示する。

---

## 優先度：中

### 9. Unicode 情報表示の強制アンラップ

**ファイル**: `Sources/NSString/NSString-Unicode.swift:80-95`

- `CFStringTransform` の結果に `{...}` が存在すると仮定して `firstMatch!`
- ICU の `u_getPropertyValueName` が非 nil と仮定して `blockNameChars!`

未割り当て文字、孤立サロゲート、変換不能な文字列などで前提が崩れると、文字情報ポップオーバー表示時にクラッシュし得る。

---

### 10. `PDFPage.pageRef!` の強制アンラップ

**ファイル**: `Sources/Extensions/PDF/PDFPageBox.swift:7-10`

```swift
self.cgPdfPage = pdfPage.pageRef!
```

ファイル由来ページでは通常存在するが、PDFKit が生成したページや壊れた文書では `pageRef` が nil になり得る。`PDFPage.pageBox` extension からも無条件に到達する。

---

### 11. GIF データと ImageIO オブジェクトの前提が強い

**ファイル**: `Sources/Converter/Converter.swift`

- 602-606行: GIF データが5バイト以上ある前提で byte 4 を置換
- 830-831行: `CFDataCreateMutable` と `CGImageDestinationCreateWithData` を強制アンラップ
- 846行: `CGImageDestinationFinalize` の戻り値を無視

通常の ImageIO 出力では低頻度だが、メモリ不足や不正データ時にクラッシュまたは不正成功判定となる。

---

### 12. 拡張属性読み込みに TOCTOU と戻り値未確認がある

**ファイル**: `Sources/Controllers/ControllerG.swift:1574-1587`

`getxattr` でサイズ取得後にそのサイズで確保し、2回目の `getxattr` の戻り値を確認していない。取得間に属性サイズが変わると、失敗後の未初期化領域を String 化する可能性がある。0バイト属性も明示処理されていない。

---

### 13. GUI のタスク中断状態にデータ競合がある

**ファイル**: `Sources/Controllers/ControllerG.swift`

- 204-208行: `runningTask`, `taskKilled`, `generationAborted`
- 268-278行: バックグラウンド側の読み書き
- 2299-2302行: メインスレッド側の読み書き

同期なしで複数スレッドから状態を変更している。Process の終了と次 Process の代入が競合すると、誤ったタスクの terminate、abort 状態の取りこぼし、Swift データ競合が起こり得る。

---

### 14. Undo/Redo Notification observer token を保持・解除していない

**ファイル**: `Sources/Editor/TeXTextView.swift:74-97`

選択変更 observer だけはプロパティに保持しているが、Undo/Redo の block observer token は保持していない。クロージャは weak self のため循環参照は避けられているものの、TextView の生成・破棄を繰り返すと不要 observer が残る。

---

### 15. コマンド補完の検索 NSRange が負値・不整合になり得る

**ファイル**: `Sources/Editor/TeXTextView-CommandCompletion.swift:139-177`

```swift
NSRange(location: 0, length: Int(completionListLocation) - 1)
```

`completionListLocation == 0` で逆方向検索に入ると length が `-1` になる。また location は UTF-16 offset なのに、残り長へ `commandCompletionList.count` を使っている。カスタム補完ファイルに絵文字・結合文字が含まれる場合、Foundation に不正 NSRange を渡す可能性がある。

---

## 優先度：低〜中

### 危険な整数 String subscript 拡張

**ファイル**: `Sources/Extensions/Foundation/StringProtocol-Extension.swift`

範囲チェックなしの整数 subscript が定義されている。現時点の直接利用は限定的だが、将来のコード追加でクラッシュを誘発しやすい。

### IBOutlet IUO の広範な使用

`ControllerG`, `ProfileController`, `TeXTextView`, `MyGlyphPopoverController` に多数存在する。正常な nib 接続時は問題ないが、接続不備、ロード順、ウィンドウ破棄後の遅延処理でクラッシュし得る。

例:

- `TeXTextView.swift:60` の `controller`
- `TeXTextView-Colorize.swift:71,117`
- `MyGlyphPopoverController.swift:321` の `textContainer!`
- `ControllerG.swift:2306-2315` の `preferenceWindow.contentView!`

### 固定正規表現への `try!`

**ファイル**: `Sources/Converter/Converter-BoundingBox.swift:107-109`

現在の pattern は定数なので即時リスクは低い。ただし pattern 変更時に変換処理中のクラッシュへ直結する。

---

## ビルド確認

2026-06-25 に以下を実施。

- `TeX2img GUI` Debug build: 成功
- `tex2img CUI` Debug build: 成功
- Swift Package: `swift-argument-parser 1.8.2`

ビルド成功は、上記の実行時クラッシュ経路が安全であることを意味しない。

---

## 推奨対応順

1. `generateCroppedPDF` の0ページ guard と PDFKit 並列処理の撤廃・隔離
2. BoundingBox の安全なパーサー化
3. bitmap サイズ上限・有限値確認と画像 Optional の防御
4. Profile 読み込み時の配列整合性修復
5. UTF-16 offset API の安全化と `String.count` 混在の解消
6. AppDelegate KVO と `MyLayoutManager` の nil 安全化
7. Unicode/PDFPage/GIF/xattr の強制アンラップ除去
8. タスク中断状態と observer の寿命管理

修正時は、既存の出力形式、ページ順、クロップ結果、コマンド補完挙動を変えないことを優先し、異常入力時のみ既存のエラー表示・失敗戻り値へフォールバックさせるのが妥当。

---

## 診断上の注意

- 本診断ではソースコードを変更していない。
- `Sparkle.framework` は診断開始時点で多数の削除と未追跡 framework が存在する作業ツリー状態だった。本診断では触れていない。
- 静的診断とビルド確認が中心であり、各異常 PDF/EPS・メモリ圧迫・Thread Sanitizer による動的再現試験は未実施。
