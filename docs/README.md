# TeX2img のドキュメント

調査報告・移行メモは `docs/` にまとめる。新しい監査報告は `audits/`、Swift移行や現代化のメモは `migration/` に追加する。文書中のソースパス・コマンドは、特記がなければリポジトリのルートを基準とする。

## 監査・不具合調査 — `audits/`

- [Ghostscript 10.07.1インストール後の実機検証](audits/ghostscript-10.07.1-2026-10-25.md)
- [本機での網羅テスト・残存するPDFKit問題（2026-10-25）](audits/comprehensive-tests-2026-10-25.md)
- [同梱ライブラリ更新・Brotli修正確認（2026-10-25）](audits/bundled-libraries-2026-10-25.md)
- [クラッシュリスク監査](audits/CRASH_RISK_AUDIT.md)

## 移行・保守メモ — `migration/`

- [macOS 12向け非推奨API対応](migration/macos12-api-update.md)
- [TeX実行ファイルの探索パス](migration/tex-discovery-paths.md)

ローカルの移行資料は `migration/SwiftMigrationNotes.md` と `migration/SwiftMigrationGuide.md` に配置する。既存の `.gitignore` に従い、この2件はGit管理対象外であり、クローン直後には存在しない。

## ビルド・配布

- [ビルド・配布手順](build-and-deploy.md)

## テスト関連

テストデータや実行スクリプトと一緒に管理する文書は、既存の `te st/` に置く。

- [変換テストの使い方・検証記録](../te%20st/verified-tests.md)
- [メッシュシェーディングの調査記録](../te%20st/github-comment-mesh-shading.md)

[プロジェクトのREADME](../README.md)
