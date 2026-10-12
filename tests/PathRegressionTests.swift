import Foundation

@main
struct PathRegressionTests {
    static func main() {
        let cases = [
            ("file.pdf", "file.svg"),
            ("/tmp/file.pdf", "/tmp/file.svg"),
            ("relative/file.pdf", "relative/file.svg"),
            ("./file.pdf", "./file.svg"),
            ("/日本語 資料/画像.原本.pdf", "/日本語 資料/画像.原本.svg"),
            ("file", "file.svg"),
            (".hidden", ".hidden.svg"),
            ("../file.pdf", "../file.svg")
        ]
        var failures = 0
        for (input, expected) in cases {
            let actual = input.replacingPathExtension("svg")
            if actual != expected {
                print("不一致: \(input) → \(actual)（期待値: \(expected)）")
                failures += 1
            }
        }
        if failures > 0 { exit(1) }
        print("拡張子置換: 相対・絶対パス8ケース成功")
    }
}
