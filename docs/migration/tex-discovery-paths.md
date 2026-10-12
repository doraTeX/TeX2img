# TeX実行ファイルの探索パス

2026-10-12に公式のインストール定義を確認。

| 配布方法 | 標準の呼び出しパス | 対応 |
| --- | --- | --- |
| Apple Silicon版Homebrewの`texlive` formula | `/opt/homebrew/bin/lualatex`など | `/opt/homebrew/bin`を追加 |
| Intel版Homebrew | `/usr/local/bin` | 既存の候補を維持 |
| MacPorts | `/opt/local/bin/lualatex`など | 既存の候補で対応 |

GUIの自動検出はプロセスのPATHと`path_helper`の結果も探索するため、Homebrewがそこに含まれる環境では従来も検出できた。しかしFinderからの起動などでは含まれる保証がなく、明示的な追加が必要だった。従来の他の探索候補間の優先順位は維持。

MacPortsは実体を`${prefix}/libexec/texlive/binaries`へ配置する。必要なマクロ等が揃ったコマンドだけを`${prefix}/bin`へリンクし、利用可能にする仕組み。`texlive-latex`は`lualatex`を登録し、エンジンは`luahbtex`を使用する。標準prefixは`/opt/local`なので、既存の探索先でよい。未構成のコマンドを拾わないよう、内部の`binaries`ディレクトリは探索先へ追加しない。

このマシンには`/opt/homebrew/bin`や`/opt/local/bin/lualatex`がないため、インストール実機での実行確認ではなく公式定義の確認。GUI Debug／Releaseのビルドは成功。

参照:

- [Homebrewの標準prefix](https://docs.brew.sh/Installation)
- [Homebrew texliveのビルド・インストール定義](https://github.com/Homebrew/homebrew-core/blob/master/Formula/t/texlive.rb)
- [MacPorts texlive共通定義](https://github.com/macports/macports-ports/blob/master/_resources/port1.0/group/texlive-1.0.tcl)
- [MacPorts texlive-latex](https://github.com/macports/macports-ports/blob/master/tex/texlive-latex/Portfile)
