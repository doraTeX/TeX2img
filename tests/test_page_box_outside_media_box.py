"""ページボックスの BoundingBox を実装そのものでコンパイルして確かめる（アプリは起動しない）。

CropBox などが MediaBox の外にある PDF では，二つの交わりが空（原点が無限大の CGRect.null）になり，
整数にするところで落ちていた。PDFKit と同じく空の箱として扱い，ほかのページの値は変えない。
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEST = r'''
import Quartz
func expect(_ name: String, _ got: String?, _ expected: String) {
    guard got == expected else { print("FAIL \(name): \(got ?? "nil") != \(expected)"); exit(1) }
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
    (path / 'Test.swift').write_text(TEST)
    sources = [str(ROOT / p) for p in ['Sources/Extensions/PDF/PDFPageBox.swift', 'Sources/Extensions/PDF/PDFDocument-Extension.swift']]
    subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(path / 'Test.swift'), *sources, '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test'), directory], timeout=30, check=True)
