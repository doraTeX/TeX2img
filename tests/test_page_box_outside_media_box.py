"""ページボックスの BoundingBox を実装そのものでコンパイルして確かめる（アプリは起動しない）。

CropBox などが MediaBox の外にある PDF では，二つの交わりが空（原点が無限大の CGRect.null）になり，
整数にするところで落ちていた。PDFKit と同じく，ページの回転にかかわらず空の箱 0 0 0 0 とし，
ほかのページの値（回転したページを含む）は変えない。整数にできない座標や，余白を足して整数の範囲を
超える座標は落とさずに失敗とし，設定のページボックスの番号は5種類のほかは MediaBox とする。
"""
import re
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEST = r'''
import Quartz
func expect(_ name: String, _ got: String?, _ expected: String) {
    guard (got ?? "nil") == expected else { print("FAIL \(name): \(got ?? "nil") != \(expected)"); exit(1) }
}
@main struct Main {
    static func main() {
        let directory = CommandLine.arguments[1]
        let box = { (file: String, type: CGPDFBox, hires: Bool) in
            PDFPageBox(filePath: directory + "/" + file, page: 1)?.bboxString(of: type, hires: hires, addHeader: true)
        }
        expect("crop box outside the media box", box("outside.pdf", .cropBox, false), "%%BoundingBox: 0 0 0 0\n")
        expect("art box outside the media box", box("outside.pdf", .artBox, false), "%%BoundingBox: 0 0 0 0\n")
        expect("hires crop box outside the media box", box("outside.pdf", .cropBox, true),
               "%%HiResBoundingBox: 0.000000 0.000000 0.000000 0.000000\n")
        expect("media box of that page", box("outside.pdf", .mediaBox, false), "%%BoundingBox: 0 0 200 200\n")
        expect("crop box inside the media box", box("inside.pdf", .cropBox, false), "%%BoundingBox: 40 30 140 131\n")
        expect("crop box over the edge of the media box", box("over.pdf", .cropBox, false), "%%BoundingBox: 140 0 200 50\n")
        expect("rotated crop box", box("rotated.pdf", .cropBox, false), "%%BoundingBox: 30 60 130 160\n")
        // A page whose MediaBox is not at the origin and not square, in the four directions: the values of before.
        for (rotation, expected) in [(0, "40 20 140 120"), (90, "20 160 120 260"), (180, "160 80 260 180"), (270, "80 40 180 140")] {
            expect("crop box turned \(rotation)", box("turned\(rotation).pdf", .cropBox, false), "%%BoundingBox: \(expected)\n")
            let hires = expected.split(separator: " ").map { String(format: "%f", Double($0)!) }.joined(separator: " ")
            expect("hires crop box turned \(rotation)", box("turned\(rotation).pdf", .cropBox, true), "%%HiResBoundingBox: \(hires)\n")
            // Outside the MediaBox: empty at 0 0 whatever the rotation (it was moved to a corner of the turned page).
            expect("outside turned \(rotation)", box("outside\(rotation).pdf", .cropBox, false), "%%BoundingBox: 0 0 0 0\n")
            expect("hires outside turned \(rotation)", box("outside\(rotation).pdf", .cropBox, true),
                   "%%HiResBoundingBox: 0.000000 0.000000 0.000000 0.000000\n")
        }
        // A saved page box number: the five boxes, any other number is the MediaBox.
        for (number, expected) in [(0, CGPDFBox.mediaBox), (1, .cropBox), (2, .bleedBox), (3, .trimBox), (4, .artBox),
                                   (5, .mediaBox), (-1, .mediaBox), (Int.max, .mediaBox), (Int.min, .mediaBox)] {
            guard CGPDFBox.pageBox(number: number) == expected else { print("FAIL page box number \(number)"); exit(1) }
        }
        if let unknown = CGPDFBox(rawValue: 7) {
            expect("a box of no number", box("turned90.pdf", unknown, false), box("turned90.pdf", .mediaBox, false) ?? "")
        }
        // Numbers that do not fit in Int, or whose corner does not: no box rather than a trap.
        let integers = { (rect: CGRect) in PDFPageBox.integerBoundingBox(of: rect).map { "\($0.0) \($0.1) \($0.2) \($0.3)" } }
        expect("integers", integers(CGRect(x: 40.5, y: 30, width: 100, height: 100.2)), "40 30 140 131")
        expect("negative integers", integers(CGRect(x: -10.5, y: -3, width: 2, height: 0)), "-11 -3 -9 -3")
        for (name, rect) in [("infinite", CGRect(x: CGFloat.infinity, y: 0, width: 1, height: 1)),
                             ("NaN", CGRect(x: 0, y: CGFloat.nan, width: 1, height: 1)),
                             ("too large", CGRect(x: 0, y: 0, width: 1e300, height: 1)),
                             ("too large a corner", CGRect(x: 9e18, y: 0, width: 9e18, height: 1))] {
            expect(name, integers(rect), "nil")
        }
        // The margins added to the bounding box of an EPS file.
        let enlarged = { (box: (Int, Int, Int, Int), margin: (Int, Int, Int, Int)) in
            enlargedBoundingBox(box, left: margin.0, bottom: margin.1, right: margin.2, top: margin.3).map { "\($0.0) \($0.1) \($0.2) \($0.3)" }
        }
        expect("margins", enlarged((0, 0, 10, 10), (1, 2, 3, 4)), "-1 -2 13 14")
        expect("left margin out of Int", enlarged((Int.min + 1, 0, 10, 10), (2, 0, 0, 0)), "nil")
        expect("top margin out of Int", enlarged((0, 0, 10, Int.max - 1), (0, 0, 0, 2)), "nil")
        expect("right margin Int.max", enlarged((0, 0, 1, 10), (0, 0, Int.max, 0)), "nil")
        print("OK")
    }
}
'''


def pdf(media, crop, rotate=0):
    objects = ['<< /Type /Catalog /Pages 2 0 R >>', '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
               f'<< /Type /Page /Parent 2 0 R /MediaBox [{media}] /CropBox [{crop}] /Rotate {rotate} /Contents 4 0 R >>',
               '<< /Length 5 >>\nstream\nBT ET\nendstream']
    out = b'%PDF-1.4\n'
    offsets = []
    for number, body in enumerate(objects, 1):
        offsets.append(len(out))
        out += f'{number} 0 obj\n{body}\nendobj\n'.encode()
    xref = len(out)
    out += f'xref\n0 {len(objects) + 1}\n0000000000 65535 f \n'.encode()
    out += b''.join(f'{offset:010d} 00000 n \n'.encode() for offset in offsets)
    out += f'trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode()
    return out


with tempfile.TemporaryDirectory(prefix='page-box-') as directory:
    path = Path(directory)
    (path / 'outside.pdf').write_bytes(pdf('0 0 200 200', '500 500 600 600'))
    (path / 'inside.pdf').write_bytes(pdf('0 0 200 200', '40.5 30 140.5 130.2'))
    (path / 'over.pdf').write_bytes(pdf('0 0 200 200', '140 -20 260 50'))
    (path / 'rotated.pdf').write_bytes(pdf('0 0 200 200', '40 30 140 130', 90))
    for rotation in (0, 90, 180, 270):
        (path / f'turned{rotation}.pdf').write_bytes(pdf('10 20 310 220', '50 40 150 140', rotation))
        (path / f'outside{rotation}.pdf').write_bytes(pdf('10 20 310 220', '500 500 600 600', rotation))
    # The function that adds the margins, taken from the converter (the rest of it needs the whole app).
    converter = (ROOT / 'Sources/Converter/Converter-BoundingBox.swift').read_text()
    helper = re.search(r'^func enlargedBoundingBox\(.*?^}\n', converter, re.S | re.M).group(0)
    (path / 'Test.swift').write_text(TEST + helper)
    sources = [str(ROOT / p) for p in ['Sources/Extensions/PDF/PDFPageBox.swift', 'Sources/Extensions/PDF/PDFDocument-Extension.swift']]
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(path / 'Test.swift'), *sources, '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test'), directory], timeout=30, check=True)
