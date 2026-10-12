# TeX2img のドキュメント

調査報告・移行メモは `docs/` にまとめる。新しい監査報告は `audits/`、Swift移行や現代化のメモは `migration/` に追加する。文書中のソースパス・コマンドは、特記がなければリポジトリのルートを基準とする。

## 監査・不具合調査 — `audits/`

- [クラッシュリスク監査](audits/CRASH_RISK_AUDIT.md)

## 移行・保守メモ — `migration/`

ローカルの移行資料は `migration/SwiftMigrationNotes.md` と `migration/SwiftMigrationGuide.md` に配置する。既存の `.gitignore` に従い、この2件はGit管理対象外であり、クローン直後には存在しない。

## ビルド・配布

- [ビルド・配布手順](build-and-deploy.md)

## テスト関連

テストデータや実行スクリプトと一緒に管理する文書は、既存の `te st/` に置く。

- [変換テストの使い方・検証記録](../te%20st/verified-tests.md)
- [メッシュシェーディングの調査記録](../te%20st/github-comment-mesh-shading.md)

[プロジェクトのREADME](../README.md)
