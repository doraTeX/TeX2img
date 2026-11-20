"""変換の途中の段階が失敗したら変換全体を失敗とし，途中のファイルを完成品にしないことを，製品の
convertPDF・EPS の枠の書き換え・余白の追加のメソッドそのものをコンパイルして確かめる（アプリは起動しない）。

下の段階（Ghostscript を呼ぶ outlinePDF と，画像を作る pdf2image）だけを代わりの処理にする。
ページの大きさを保つ EPS では，元の PDF のページと二つの枠がそろったときだけ枠を書き換え，
そろわなければ元の EPS を残して失敗とする（以前は両方の枠を空欄にして成功としていた）。
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def method(source, first, after):
    start = source.index(first)
    return source[start:source.index(after, start)].replace('private func', 'func')


def main():
    converter = (ROOT / 'Sources/Converter/Converter.swift').read_text()
    bounding = (ROOT / 'Sources/Converter/Converter-BoundingBox.swift').read_text()
    code = r'''import Quartz
extension String {
    var pathExtension: String { (self as NSString).pathExtension }
    func appendingPathComponent(_ a: String) -> String { (self as NSString).appendingPathComponent(a) }
    func substring(with range: NSRange) -> String { (self as NSString).substring(with: range) }
    var nsLength: Int { (self as NSString).length }
}
extension Data {
    init?(filePath: String) { try? self.init(contentsOf: URL(fileURLWithPath: filePath)) }
    func writeToPath(_ p: String) -> Bool { (try? self.write(to: URL(fileURLWithPath: p))) != nil }
}
final class FakeController {
    var errors = [String]()
    func showFileGenerationError(_ path: String) { errors.append(path) }
}
final class Shell {
    let workingDirectory: String
    init(_ directory: String) { workingDirectory = directory }
    let fileManager = FileManager.default
    let tempFileBaseName = "temp"
    var transparentFlag = false
    var leftMargin = 0, rightMargin = 0, topMargin = 0, bottomMargin = 0
    var hasMargin: Bool { [leftMargin, rightMargin, topMargin, bottomMargin].contains { $0 > 0 } }
    let emptyPageFlags = [false]
    var pageBoxType: CGPDFBox = .mediaBox
    let controller: FakeController? = FakeController()
    func exitCurrentThread() -> Bool { false }
    // The lower steps: they write their output in the working folder, then succeed or fail.
    var outlineSucceeds = true
    var imageCalls = 0
    func outlinePDF(_ p: String, intermediateOutlinedFileName: String, outputFileName: String, page: UInt, addMargin: Bool,
                    useCache: Bool, fillBackground: Bool) -> Bool {
        try! Data(eps.utf8).write(to: URL(fileURLWithPath: workingDirectory.appendingPathComponent(outputFileName)))
        return outlineSucceeds
    }
    func pdf2image(_ p: String, outputFileName: String, page: UInt, crop: Bool) -> Bool { imageCalls += 1; return true }
    // The bounding box Ghostscript finds on a page (the crop without keeping the page size).
    func bboxString(ofPdf pdfPath: String, page: Int, hires: Bool) -> String? {
        hires ? "%%HiResBoundingBox: 1.500000 2.500000 3.500000 4.500000\n" : "%%BoundingBox: 1 2 4 5\n"
    }
'''
    code += method(converter, '    private func convertPDF(_ pdfFileName:', '    private func copyTarget(')
    # The three ways the boxes of an EPS file are rewritten: the crop, the empty page, the page size kept.
    code += method(converter, '    private func replaceEpsBBox(_ epsName: String, withBBoxOfPdf', '    private func pdf2eps')
    code += method(bounding, '    func bboxOf(data:', '    /// gsが出力')
    code += method(bounding, '    func replaceBBoxOf(epsPath:', '    /// PDFの特定')
    code += '}\n' + bounding[bounding.index('func enlargedBoundingBox('):]
    code += r'''
let emptyBBox = "%%BoundingBox: 0 0 0 0\n"
let eps = "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 10 10\n%%HiResBoundingBox: 0.250000 0.250000 9.750000 9.750000\n%%EOF\n"
var failures = 0
func expect(_ name: String, _ ok: Bool) { if !ok { print("FAIL \(name)"); failures += 1 } }
func read(_ path: String) -> String? { try? String(contentsOfFile: path, encoding: .utf8) }

@main struct Main {
    static func main() {
        let directory = CommandLine.arguments[1]
        let output = { (name: String) in directory + "/" + name }
        // An outline step that fails: no EPS, PDF or image is made from what it left.
        for (name, extensionName) in [("eps", "eps"), ("pdf", "pdf"), ("png", "png")] {
            let shell = Shell(directory)
            shell.outlineSucceeds = false
            // The EPS file is moved to the output path; the PDF and image outputs are in the working folder.
            let final = extensionName == "eps" ? output("final-failed.eps") : "final-failed." + extensionName
            let result = shell.convertPDF("in.pdf", intermediateOutlinedFileName: "stage-\(name).eps", outputFileName: final,
                                          page: 1, useCache: false, skipEmptyPage: false)
            expect("\(name): a failed outline step fails the conversion", !result)
            if extensionName == "eps" {
                expect("eps: no output file from a failed step", !FileManager.default.fileExists(atPath: final))
                expect("eps: the file of the failed step is not moved",
                       FileManager.default.fileExists(atPath: output("stage-eps.eps")))
            }
            expect("\(name): no image from a failed step", shell.imageCalls == 0)
        }
        // The same steps succeeding: the EPS file is moved to the output, the image is made.
        let shell = Shell(directory)
        let finalEPS = output("final.eps")
        expect("eps: conversion", shell.convertPDF("in.pdf", intermediateOutlinedFileName: "stage.eps", outputFileName: finalEPS,
                                                   page: 1, useCache: false, skipEmptyPage: false))
        expect("eps: the output file", read(finalEPS) == eps)
        expect("png: conversion", shell.convertPDF("in.pdf", intermediateOutlinedFileName: "stage.eps", outputFileName: "final.png",
                                                   page: 1, useCache: false, skipEmptyPage: false) && shell.imageCalls == 1)
        // Margins of a transparent EPS file still go to both boxes.
        let margins = Shell(directory)
        margins.transparentFlag = true
        margins.leftMargin = 2; margins.rightMargin = 3; margins.topMargin = 4; margins.bottomMargin = 1
        let marginEPS = output("margins.eps")
        expect("eps with margins", margins.convertPDF("in.pdf", intermediateOutlinedFileName: "stage-margins.eps", outputFileName: marginEPS,
                                                      page: 1, useCache: false, skipEmptyPage: false))
        let text = read(marginEPS) ?? ""
        expect("margins in both boxes: \(text)", text.contains("%%BoundingBox: -2 -1 13 14\n") && text.contains("%%HiResBoundingBox: -1.75 -0.75 12.75 13.75\n"))

        // The page box of a PDF that cannot be read: the EPS file stays as it is, and the step fails with a message.
        let keep = Shell(directory)
        try! Data(eps.utf8).write(to: URL(fileURLWithPath: output("keep.eps")))
        expect("no page: the step fails", !keep.replaceEpsBBox("keep.eps", withPageBoxOfPdf: "no-such.pdf", page: 1))
        expect("no page: the EPS file is kept", read(output("keep.eps")) == eps)
        expect("no page: an error is shown", keep.controller?.errors == [output("keep.eps")])
        expect("no such page: the step fails", !keep.replaceEpsBBox("keep.eps", withPageBoxOfPdf: "page.pdf", page: 2))
        expect("no such page: the EPS file is kept", read(output("keep.eps")) == eps)
        // An EPS file without one of its box lines: the step fails and the file stays as it is.
        for missing in ["%%BoundingBox: 0 0 10 10\n", "%%HiResBoundingBox: 0.250000 0.250000 9.750000 9.750000\n"] {
            let boxless = eps.replacingOccurrences(of: missing, with: "")
            try! Data(boxless.utf8).write(to: URL(fileURLWithPath: output("boxless.eps")))
            keep.pageBoxType = .cropBox
            expect("no \(missing): the step fails", !keep.replaceEpsBBox("boxless.eps", withPageBoxOfPdf: "page.pdf", page: 1))
            expect("no \(missing): the file is kept", read(output("boxless.eps")) == boxless)
        }
        keep.pageBoxType = .mediaBox
        // A page that can be read: both boxes are those of the page box.
        keep.pageBoxType = .cropBox
        expect("a page: the step succeeds", keep.replaceEpsBBox("keep.eps", withPageBoxOfPdf: "page.pdf", page: 1))
        let replaced = read(output("keep.eps")) ?? ""
        expect("a page: both boxes \(replaced)", replaced.contains("%%BoundingBox: 40 30 140 130\n")
               && replaced.contains("%%HiResBoundingBox: 40.000000 30.000000 140.000000 130.000000\n"))

        // Only the header comments of the file are its boxes: not other comments, not an embedded document.
        let head = "%!PS-Adobe-3.0 EPSF-3.0\n%%Creator: test\n"
        let boxes = "%%BoundingBox: 0 0 10 10\n%%HiResBoundingBox: 0.250000 0.250000 9.750000 9.750000\n"
        let body = "%%EndComments\n%%BeginProlog\n%%EndProlog\nnewpath\n"
        let comments = "% %%BoundingBox: 0 0 10 10\n%%BoundingBox: 0 0 10 10\n%%HiResBoundingBox: 0.25 0.25 9.75 9.75\n"
        let embedded = "%%BeginDocument: inner.eps\n%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 10 10\n"
            + "%%HiResBoundingBox: 0.25 0.25 9.75 9.75\n%%EndComments\n%%EndDocument\n"
        let paths: [(String, (Shell, String) -> Bool)] = [
            ("page size kept", { $0.replaceEpsBBox($1, withPageBoxOfPdf: "page.pdf", page: 1) }),
            ("crop", { $0.replaceEpsBBox($1, withBBoxOfPdf: "page.pdf", page: 1) }),
            ("empty page", { $0.replaceEpsBBoxWithEmptyBBox($1) }),
        ]
        let expected = ["page size kept": ("40 30 140 130", "40.000000 30.000000 140.000000 130.000000"),
                        "crop": ("1 2 4 5", "1.500000 2.500000 3.500000 4.500000"),
                        "empty page": ("0 0 0 0", "0.000000 0.000000 0.000000 0.000000")]
        for (pathName, rewrite) in paths {
            let shell = Shell(directory)
            shell.pageBoxType = .cropBox
            for (caseName, file) in [("boxes only in the body comments", head + body + comments),
                                     ("boxes only in an embedded document", head + body + embedded),
                                     ("boxes in an ordinary comment of the header", head + "% %%BoundingBox: 0 0 10 10\n" + body),
                                     ("integer box at the end", head + "%%BoundingBox: (atend)\n%%HiResBoundingBox: (atend)\n" + body + "%%Trailer\n" + boxes),
                                     ("boxes after an empty line", head + "\n" + boxes + body)] {
                try! Data(file.utf8).write(to: URL(fileURLWithPath: output("nested.eps")))
                expect("\(pathName), \(caseName): the step fails", !rewrite(shell, "nested.eps"))
                expect("\(pathName), \(caseName): the file is kept", read(output("nested.eps")) == file)
            }
            // The boxes of the header are rewritten, and only they; those of an embedded document stay.
            let (integer, hires) = expected[pathName]!
            for (caseName, file, newline) in [("header and embedded", head + boxes + body + embedded, "\n"),
                                              ("CR LF", (head + boxes + body).replacingOccurrences(of: "\n", with: "\r\n"), "\r\n")] {
                try! Data(file.utf8).write(to: URL(fileURLWithPath: output("header.eps")))
                expect("\(pathName), \(caseName): the step succeeds", rewrite(shell, "header.eps"))
                let wanted = file.replacingOccurrences(of: "%%BoundingBox: 0 0 10 10" + newline + "%%HiResBoundingBox: 0.250000 0.250000 9.750000 9.750000",
                                                       with: "%%BoundingBox: \(integer)" + newline + "%%HiResBoundingBox: \(hires)")
                expect("\(pathName), \(caseName): only the header boxes, no empty line: \(read(output("header.eps")) ?? "nil")",
                       read(output("header.eps")) == wanted)
            }
        }
        if failures > 0 { exit(1) }
        print("OK")
    }
}
'''
    with tempfile.TemporaryDirectory(prefix='eps-conversion-failures-') as directory:
        path = Path(directory)
        page = PdfPage('0 0 200 200', '40 30 140 130')
        (path / 'page.pdf').write_bytes(page)
        (path / 'Test.swift').write_text(code)
        subprocess.run(['xcrun', 'swiftc', '-parse-as-library', str(path / 'Test.swift'),
                        str(ROOT / 'Sources/Extensions/PDF/PDFPageBox.swift'),
                        str(ROOT / 'Sources/Extensions/PDF/PDFDocument-Extension.swift'), '-o', str(path / 'test')], check=True)
        return subprocess.run([str(path / 'test'), directory], timeout=60).returncode


def PdfPage(media, crop):
    objects = ['<< /Type /Catalog /Pages 2 0 R >>', '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
               f'<< /Type /Page /Parent 2 0 R /MediaBox [{media}] /CropBox [{crop}] /Contents 4 0 R >>',
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


if __name__ == '__main__':
    sys.exit(main())
