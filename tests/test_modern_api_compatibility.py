"""macOS 12向けAPI移行: 実際のCLI色解析、形式識別子、旧ドラッグデータの互換性。"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'Sources/CLI/mainc.swift').read_text()
start = source.index('    private func parseBackgroundColor(')
end = source.index('    private func resolveFlag(', start)
method = source[start:end].replace('private func', 'func', 1)
code = r'''
import AppKit
import UniformTypeIdentifiers

enum Tex2imgCLIError: Error { case failed }
struct Parser {
__METHOD__
}
@main struct Test {
    static func main() throws {
        let parser = Parser()
        let cases: [(String, [Int])] = [
            ("#cFc", [204,255,204]), ("CCFFCC", [204,255,204]),
            ("#123456", [18,52,86]), ("123", [17,34,51]),
            ("000", [0,0,0]), ("FFFFFF", [255,255,255]),
            ("magenta", [255,0,255]), ("255 0 255", [255,0,255])
        ]
        for (text, expected) in cases {
            let color = try parser.parseBackgroundColor(text).usingColorSpace(.deviceRGB)!
            let actual = [color.redComponent, color.greenComponent, color.blueComponent].map { Int(($0 * 255).rounded()) }
            precondition(actual == expected, text)
        }
        for invalid in ["#12", "GGGGGG", "256 0 0", "1 2"] {
            do {
                _ = try parser.parseBackgroundColor(invalid)
                preconditionFailure("不正な色を受理: \(invalid)")
            } catch Tex2imgCLIError.failed {}
        }
        // 圧縮SVGやTeXも落とさず、すべての従来拡張子を表現できる。
        for ext in ["eps", "pdf", "svg", "svgz", "jpg", "png", "gif", "tiff", "bmp", "tex", "ps"] {
            let type = UTType(filenameExtension: ext)!
            precondition(type.tags[.filenameExtension]?.contains(ext) == true, ext)
        }
        // 旧版で作った非secure archiveも新デコーダーで読める。
        let rows = IndexSet([0, 2, 5])
        for secure in [false, true] {
            let data = try NSKeyedArchiver.archivedData(withRootObject: rows, requiringSecureCoding: secure)
            let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexSet.self, from: data) as IndexSet?
            precondition(decoded == rows)
        }
        print("色解析12ケース・11拡張子・新旧ドラッグデータの互換性: 成功")
    }
}
'''.replace('__METHOD__', method)
with tempfile.TemporaryDirectory(prefix='tex2img-api-regression-') as directory:
    path = Path(directory)
    (path / 'Test.swift').write_text(code)
    subprocess.run(['swiftc', '-parse-as-library', str(path / 'Test.swift'),
                    str(ROOT / 'Sources/Extensions/AppKit/NSColor-Extension.swift'),
                    '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True, timeout=15)
