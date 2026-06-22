# TeX2img ビルド・デプロイ手順

macOS 版 TeX2img のビルドと配布物作成の手順です。AI エージェントや開発者が引き継ぎやすいよう、スクリプトと Xcode 設定の関係をまとめています。

## プロジェクト構成

| ターゲット | Xcode スキーム | 成果物 | 用途 |
|-----------|----------------|--------|------|
| **TeX2img** | `TeX2img GUI` | `TeX2img.app` | GUI アプリ |
| **tex2img** | `tex2img CUI` | `tex2img` | コマンドライン版 |

両ターゲットは `TeX2img.xcodeproj` に含まれ、多くの Swift ソースを共有しています。

## 重要: GUI バンドルへの CUI 同梱

**GUI 版を配布する場合、必ず `TeX2img.app` の中に CUI 版 `tex2img` が含まれている必要があります。**

Xcode のビルドフェーズ **「Copy Command Line Tools」** が、`tex2img` ターゲットの成果物を GUI バンドルへコピーします。

```
TeX2img.app/
└── Contents/
    ├── SharedSupport/
    │   └── bin/
    │       └── tex2img          ← CUI バイナリ（必須）
    └── Resources/
        ├── mupdf/mudraw
        ├── pdftops/...
        └── ...
```

- 配置先は `Contents/Resources/bin` ではなく **`Contents/SharedSupport/bin`** です。
- GUI の「CUI をインストール」機能は、このパスへ `/usr/local/bin/tex2img` のシンボリックリンクを張ります（`ControllerG.swift`）。
- `TeX2img` ターゲットは `tex2img` ターゲットに **PBXTargetDependency** で依存しているため、GUI ビルド時に CUI も先にビルドされます。

### 同梱の確認

```bash
scripts/verify-bundle.sh Release
# または Debug
scripts/verify-bundle.sh Debug
```

`scripts/build.sh TeX2img` はビルド後に自動でこの検証を実行します。

同梱版は **CodeSignOnCopy** で再署名されるため、standalone の `tex2img` とバイト単位では一致しません。検証はバージョン文字列の一致で行います。

## ビルド

### 推奨: ラッパースクリプト

```bash
# GUI（CUI 同梱つき）— 日常開発
scripts/build.sh TeX2img Debug

# CUI のみ
scripts/build.sh tex2img Debug

# リリース用
scripts/build.sh TeX2img Release
scripts/build.sh tex2img Release
```

### 内部: safe-build.sh

`scripts/build.sh` は `scripts/safe-build.sh` を呼び出します。直接使う場合:

```bash
scripts/safe-build.sh TeX2img [Debug|Release]
scripts/safe-build.sh tex2img [Debug|Release]
scripts/safe-build.sh all     [Debug|Release]
```

#### ビルド順序に関する注意

共有 Swift ソースを両ターゲットがリンクするため、**並列ビルドでリンクエラーや誤ったオブジェクト混入**が起きることがあります。`safe-build.sh` では次の順序を守ります。

| コマンド | 手順 |
|----------|------|
| `TeX2img` | 先に `tex2img CUI` → 次に `TeX2img GUI` |
| `tex2img` | `tex2img CUI` のみ |
| `all` | 先に `TeX2img GUI` → 次に `tex2img CUI` |

**配布用 GUI を作るときは `TeX2img`（または `build.sh TeX2img`）を使い、`verify-bundle.sh` で同梱を確認してください。**

### DerivedData の場所

デフォルト: `~/Developer/DerivedData/TeX2img`

環境変数 `DERIVED_DATA` で変更可能です。

ビルド成果物:

```
~/Developer/DerivedData/TeX2img/Build/Products/
├── Debug/
│   ├── TeX2img.app
│   │   └── Contents/SharedSupport/bin/tex2img
│   └── tex2img
└── Release/
    ├── TeX2img.app
    ├── tex2img
    ├── deploy.sh      # GUI デプロイ用（ビルド時に生成）
    └── deployc.sh     # CUI デプロイ用（ビルド時に生成）
```

### Xcode からビルドする場合

1. スキーム **`TeX2img GUI`** を選ぶ（`tex2img CUI` だけではバンドルは作れない）
2. Product → Build（⌘B）
3. `scripts/verify-bundle.sh Debug` で同梱確認

スキーム `TeX2img GUI` は `parallelizeBuildables = NO` になっています。

## バージョン番号の更新

リリース前に次の **2 箇所** を揃えて更新します。

| ファイル | キー / 変数 |
|----------|-------------|
| `Resources/Info.plist` | `CFBundleVersion`（GUI） |
| `Sources/CLI/mainc.swift` | `let tex2imgVersion`（CUI） |

`deployc.sh` の zip 名はビルド時に `mainc.swift` から自動生成されます。`deploy.sh` の DMG 名は `Info.plist` の `CFBundleVersion` を参照します。

## デプロイ

### CUI 版（zip）

```bash
scripts/deploy-cui.sh
```

1. `tex2img` を Release ビルド
2. `Build/Products/Release/deployc.sh` を実行
3. `tex2imgcMac{version}.zip` が生成される（中身は `tex2img` 単体）

手動で行う場合:

```bash
scripts/build.sh tex2img Release
cd ~/Developer/DerivedData/TeX2img/Build/Products/Release
./deployc.sh
```

### GUI 版（DMG + Sparkle Appcast）

#### 開発・手元確認用（公証なし）

```bash
scripts/deploy-gui.sh
```

1. `TeX2img.app` を Release ビルド（**CUI 同梱を verify**）
2. `Build/Products/Release/deploy.sh` を実行

#### 配布用（Archive + 公証 — 推奨）

Xcode の **Product → Archive → Distribute App → Developer ID** と同等の処理をスクリプトで行います。

```bash
scripts/release-gui.sh
```

1. `xcodebuild archive` で Release `.xcarchive` を作成（Developer ID 署名済み）
2. アーカイブ内 `TeX2img.app` の CUI 同梱を検証
3. `notarytool submit` で **アプリを公証** → `stapler staple`
4. 公証済み app から DMG を作成・署名
5. **DMG も公証** → staple
6. Sparkle Appcast（DSA 署名・ファイルサイズ）を更新

個別に実行する場合:

```bash
scripts/archive-gui.sh                              # .xcarchive のみ
scripts/notarize.sh path/to/TeX2img.app             # app の公証
scripts/make-gui-dmg.sh path/to/TeX2img.app         # DMG 作成
scripts/notarize.sh path/to/TeX2img_2.4.3.dmg        # DMG の公証
scripts/publish-gui.sh path/to/TeX2img_2.4.3.dmg    # Appcast 更新
```

アーカイブの場所（デフォルト）: `~/Developer/DerivedData/TeX2img/Archives/TeX2img.xcarchive`

#### 公証の認証情報

`notarytool` 用の認証を **いずれか一方** 設定します。

**推奨: キーチェーン・プロファイル**（一度だけ登録）:

```bash
xcrun notarytool store-credentials tex2img-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id 86GWZ48925
# パスワードには appleid.apple.com で発行した App 用パスワードを入力
```

リリース時:

```bash
export NOTARY_KEYCHAIN_PROFILE=tex2img-notary
scripts/release-gui.sh
```

**代替: 環境変数**（CI 向け）:

```bash
export NOTARY_APPLE_ID=...
export NOTARY_PASSWORD=...    # App 用パスワード（app-specific password）
export NOTARY_TEAM_ID=86GWZ48925
```

`deploy-gui.sh` との違い:

| | `deploy-gui.sh` | `release-gui.sh` |
|--|-----------------|------------------|
| ビルド | 通常の Release build | `xcodebuild archive` |
| 公証 | なし | app + DMG |
| DMG 元 | `../TeX2imgDmg/Disk Image.dmg` テンプレート | 公証済み app から `hdiutil create` |
| Appcast | `deploy.sh`（ビルド時生成） | `publish-gui.sh` |

テンプレート DMG（`TeX2imgDmg/Disk Image.dmg`）は `deploy-gui.sh` 専用です。`release-gui.sh` では不要です。

#### Xcode Organizer からエクスポートする場合

Archive 後に GUI でエクスポートする従来フローも利用できます。コマンドラインからエクスポートする場合:

```bash
scripts/archive-gui.sh
xcodebuild -exportArchive \
  -archivePath ~/Developer/DerivedData/TeX2img/Archives/TeX2img.xcarchive \
  -exportPath ~/Developer/DerivedData/TeX2img/Export \
  -exportOptionsPlist scripts/ExportOptions.plist
# 続けて notarize.sh / make-gui-dmg.sh / publish-gui.sh
```

#### リポジトリ外に必要なもの

| パス（リポジトリの兄弟） | 用途 |
|--------------------------|------|
| `../TeX2imgDmg/Disk Image.dmg` | DMG テンプレート。中身を最新 `TeX2img.app` で更新したもの |
| `../TeX2img_Appcast/TeX2img_Appcast.xml` | Sparkle 用 Appcast |
| `../設定/証明書/Sparkle/dsa_priv.pem` | DSA 署名鍵 |

#### deploy.sh が行うこと

1. `TeX2img_{version}.dmg` をテンプレートから配置
2. DMG に **Developer ID Application** で codesign
3. DSA 署名を計算し Appcast XML を更新

`deploy.sh` / `deployc.sh` は Xcode の Run Script ビルドフェーズで **毎回上書き生成** されます。リポジトリ直下の `deployc.sh` はサンプル／古い生成物であり、配布には `Build/Products/Release/` 内のものを使います。

## 動作確認のヒント

```bash
# バンドル内 CUI のバージョン
TeX2img.app/Contents/SharedSupport/bin/tex2img --version

# スタンドアロン CUI（PATH の古い tex2img に注意）
~/Developer/DerivedData/TeX2img/Build/Products/Debug/tex2img --version

# GUI を開かずにバンドル内ツールのパスを確認
ls -la ~/Developer/DerivedData/TeX2img/Build/Products/Debug/TeX2img.app/Contents/SharedSupport/bin/
```

網羅的な変換テストは `te st/` ディレクトリを参照（`te st/verified-tests.md`）。

## スクリプト一覧

| スクリプト | 説明 |
|-----------|------|
| `scripts/safe-build.sh` | xcodebuild ラッパー（DerivedData 固定・順序制御） |
| `scripts/build.sh` | ビルド + GUI 時は bundle 検証 |
| `scripts/verify-bundle.sh` | `SharedSupport/bin/tex2img` の存在・一致確認 |
| `scripts/deploy-cui.sh` | Release CUI ビルドと zip 作成 |
| `scripts/deploy-gui.sh` | Release GUI ビルドと DMG/Appcast 更新（公証なし） |
| `scripts/archive-gui.sh` | `xcodebuild archive`（配布用 .xcarchive） |
| `scripts/notarize.sh` | Notarization Service への提出と staple |
| `scripts/make-gui-dmg.sh` | 公証済み app から DMG 作成・署名 |
| `scripts/publish-gui.sh` | DMG の Sparkle Appcast 更新 |
| `scripts/release-gui.sh` | Archive → 公証 → DMG → Appcast の一括リリース |
| `scripts/ExportOptions.plist` | `-exportArchive` 用（Developer ID） |

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| `SharedSupport/bin/tex2img` がない | `TeX2img GUI` スキームでビルドしたか確認。`tex2img CUI` だけでは不十分 |
| バンドル内と standalone の tex2img が不一致 | `scripts/build.sh TeX2img` で再ビルド |
| リンクエラー・変なシンボル | `safe-build.sh` の順序付きビルドを使う。`xcodebuild -jobs 1` |
| `deploy-gui.sh` が DMG テンプレートで失敗 | `../TeX2imgDmg/Disk Image.dmg` を用意し、最新 app を反映 |
| テストで pdftops が動かない | バンドル内 `pdftops` の codesign。`te st/run_verified_tests.py` 参照 |