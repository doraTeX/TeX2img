# Sparkle 2.10.0

2026-10-12に公式最新安定版を取得。

- リリース: https://github.com/sparkle-project/Sparkle/releases/tag/2.10.0
- アーカイブ: https://github.com/sparkle-project/Sparkle/releases/download/2.10.0/Sparkle-2.10.0.tar.xz
- SHA-256: `c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c`
- GitHub Release APIのdigestと一致。展開直後の`Sparkle.framework`は`codesign --verify --deep --strict`に成功。
- フレームワーク本体はリポジトリルートの`Sparkle.framework`。arm64／x86_64の両方を含み、最低OSは12.0。
- `bin/`も同一リリースへ更新。配布スクリプトはこのディレクトリの`sign_update`を使用。
- 署名付きGUI／CLIのDebug／Releaseビルド成功。GUI起動後の「アップデートを確認」で公開Appcastから「公開最新版3.0.1、実行中3.0.2」の結果表示を確認。
- 更新のインストール、公開サーバーへの配布、公証は実施していない。

同梱ライセンスは`LICENSE`を参照。
