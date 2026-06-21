プロジェクト全体をSwiftに書き換えたい。別のブランチを作って，そこでSwiftへの全面移行計画を遂行しよう。まずは同じ機能を持つSwiftコードに書き換えてゆこう。どうしてもSwiftに機械的に置き換えられないようなプリミティブなC言語コードなどがあればそこでまた指示を仰いで。

# 移植にあたっての注意
* rg は /usr/local/tetex/bin/rg にあるので適宜利用すること。fdも同じフォルダにある。
* クラス単位で1つずつSwift化して，正しくビルドされるかどうかテストして，成功するたびにこまめにgit commit してゆくこと。
* マイグレーション完了後は，不要な @objc などは抹消すること。XIBの中まで見て，@objc 修飾子の必要性の有無を慎重に判断すること。
* @objc 修飾子の数は極力少なくしたい。xib側からの設定で済むのであればそうすることで，swiftソースコード内の @objc 修飾子の数は減らして。
* /bin/sh -c '...' とコールするのはOSコマンドインジェクションの恐れがあって望ましくない。Processのargumentsを与える形にリファクタリングすること。その際，元の system("...") における引数中の空白文字のエスケープなどのための，シングルクォテーション・ダブルクォテーションの扱いに慎重になること。（環境変数設定が必要な場合も Process で可能か？要確認）
* obsoleteになったAPIの現代的なものへの置き換えとかもやがてはしなくてはいけないが，それはSwift化が終わった後でよい。
* 後で現代化すべきobsoleteなAPIの使用箇所は，SwiftMigrationNotes.md というファイルを作ってそちらにまとめておいて。
* Objective-Cの main.m を単純に main.swift に置き換える必要はない。AppDelegate に @main を付ければ済むのであればそうして。無駄な main.swift は作らないこと。（CUI版の mainc.swift は必要ならそれは残してよい。）
* ObjCBool を使って isDirectory判定しているところは，SwiftのURLResourceValues.isDirectory を使うなどして，同じ意味で ObjCBool を使わない実装に差しかえて。
* 作業完了後，@objc や ObjCBool などが残っていないかどうかチェック。Objective-C とのブリッジは最小限にしたい。
* エラー発生時は即座にgit revert可能な状態を保つ


# Swiftの書き方のスタイル
* Swift 5 で書くこと。
* Swift のguard 構文で，else {...} の中身が return の1文だけの場合は，else { return false } みたいに1行にまとめて。
* セミコロン区切りで1行の中に複数の文を並べるのは禁止。必ず1文ごとに改行すること。
* NSString, NSArray, NSDictionary（およびそれぞれのmutable版）は，できるだけSwift標準のString, Array, Dictionary 等を使うように書き換えて。ただし，外から見た動作を変えないように十分に注意して。
* NSNotification も Notification に置き換えて。
* NSTemporaryDirectory も FileManager.default.temporaryDirectory に置き換える。

### CUI版 コマンドライン引数処理の移植方針（更新）
- CUIツール部分は **Swift Argument Parser** に全面移行する。
- getopt.h由来の「オプション最短マッチ（prefix abbreviation）」機能は**再現しない**。
  - 理由：Argument Parserは明示性を重視しており、曖昧な最短一致はデフォルトでサポートされていない。
  - 対応：ユーザーはフルオプション名（または定義した短縮 `-v`）を入力する形に変更。


* ビルド動作確認の上，終わったらcommitすること。
* 作業ごとに SwiftMigrationNotes.md のドキュメントも更新すること。


