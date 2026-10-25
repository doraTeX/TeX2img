## pgfplotsメッシュ問題の追調査（2026-10-25）

詳細は [PDFKit保存経路の調査報告](../docs/audits/pdfkit-preservation-2026-10-25.md) を参照。

### 原因の切り分けを更新

PDFKit保存全般で必ず壊れるわけではなかった。
読み込んだ文書をそのまま編集・保存する場合は、MediaBox/CropBoxや非表示の原稿注釈を変更してもメッシュを保持できた。
新規PDFDocumentへページをinsertする、複数ページからremovePageで抽出する、PDFPage.dataRepresentationを使う、Core Graphicsで描き直す場合に問題を再現した。

再描画後にはShadingType 4が画像パターンへ変わり、パターンのBBoxには約±8.99×10^307の異常な座標が入る。
Quartzで読むと面が失われ、別のレンダラーで面が見えても画像化による劣化が残る。

### 今回改善した範囲

`generateCroppedPDF`でページ構成を変えない場合は元の文書を保存するよう修正した。
既存の単一ページ・透過・`--with-text`の再現ケースは、1,521個のメッシュを保持する。
余白指定、アウトライン化、回転・非ゼロ原点、日本語の原稿埋め込みと再取得も検査している。

```bash
./tex2img --resolution 6 --workingdir current --with-text pgfplots-surf.pdf ./mesh-shading/out.pdf
```

この基本ケースは `run_verified_tests.py` で80ケースとは別枠の `PASS` として確認する。

### 保留する範囲

背景合成、複数ページからの抽出、複数PDFの結合には依然として再描画経路が残る。
同梱MuPDFで抽出・結合できることは確認したが、単純な結合置換では元のText注釈が失われた。
原稿・注釈、ページ参照、回転、色管理などを維持する設計と検査が必要なため、一般対応は保留する。

汎用対応でも、qpdfの追加同梱が必須とは限らない。
現在の同梱MuPDFを活用できる可能性があり、元文書の構成を維持する保存では原稿注釈も保持できる。
