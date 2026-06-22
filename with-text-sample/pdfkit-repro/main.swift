import AppKit
import Foundation
import PDFKit

enum Mode: String {
    case rewrite = "rewrite"
    case crop = "crop"
    case embed = "embed"
    case cropAndEmbed = "crop-and-embed"
    case cgDraw = "cg-draw"
}

struct Options {
    let inputPath: String
    let outputPath: String
    let mode: Mode
}

func parseArgs() -> Options? {
    var args = Array(CommandLine.arguments.dropFirst())
    guard args.count >= 2 else { return nil }

    var mode = Mode.rewrite
    if let flagIndex = args.firstIndex(of: "--mode"), flagIndex + 1 < args.count {
        guard let parsed = Mode(rawValue: args[flagIndex + 1]) else { return nil }
        mode = parsed
        args.remove(at: flagIndex + 1)
        args.remove(at: flagIndex)
    }

    return Options(inputPath: args[0], outputPath: args[1], mode: mode)
}

func usage() {
    let program = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "pdfkit-repro"
    fputs(
        """
        usage:
          \(program) [--mode MODE] INPUT.pdf OUTPUT.pdf

        MODE:
          rewrite        PDFDocument で読み込み→そのまま書き出し
          crop           TeX2img と同様に MediaBox/CropBox を変更して書き出し
          embed          非表示 Text 注釈を追加して書き出し（embedTeXSource 相当）
          crop-and-embed crop の後に embed
          cg-draw        CGContext.drawPDFPage で 1 ページを書き出し

        """,
        stderr
    )
}

/// TeX2img の cropPage と同じ bbox 取得（Ghostscript bbox → 整数）
func boundingBoxIntegers(for pdfPath: String, pageIndex: Int) -> (lx: Int, ly: Int, ux: Int, uy: Int)? {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [
        "-c",
        """
        rungs -dBATCH -dNOPAUSE -sDEVICE=bbox -c '<< /WhiteIsOpaque true >> setpagedevice' -f "\(pdfPath)" 2>&1 \
        | awk '/%%BoundingBox:/{print $2,$3,$4,$5; exit}'
        """,
    ]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !line.isEmpty else { return nil }

    let parts = line.split(separator: " ")
    guard parts.count == 4,
          let lx = Int(parts[0]),
          let ly = Int(parts[1]),
          let ux = Int(parts[2]),
          let uy = Int(parts[3]) else { return nil }

    return (lx, ly, ux, uy)
}

/// Converter.cropPage と同等の処理
func cropPageLikeTeX2img(page: PDFPage, pdfPath: String, pageNumber: Int) -> PDFPage? {
    guard let bbox = boundingBoxIntegers(for: pdfPath, pageIndex: pageNumber - 1) else {
        fputs("error: bbox の取得に失敗しました\n", stderr)
        return nil
    }

    let mediaBox = page.bounds(for: .mediaBox)
    let mboxLx = mediaBox.minX
    let mboxLy = mediaBox.minY

    let w = CGFloat(bbox.ux - bbox.lx)
    let h = CGFloat(bbox.uy - bbox.ly)
    let lx = mboxLx + CGFloat(bbox.lx)
    let ly = mboxLy + CGFloat(bbox.ly)

    guard w > 0, h > 0 else { return page }

    let newMediaBox = CGRect(x: lx, y: ly, width: w, height: h)
    page.setBounds(newMediaBox, for: .mediaBox)
    page.setBounds(newMediaBox, for: .cropBox)
    return page
}

func exportViaCGDraw(page: PDFPage, to path: String) -> Bool {
    guard let pageRef = page.pageRef else { return false }
    var mediaBox = page.bounds(for: .mediaBox)
    guard let context = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &mediaBox, nil) else {
        return false
    }
    context.beginPDFPage(nil)
    context.drawPDFPage(pageRef)
    context.endPDFPage()
    context.closePDF()
    return true
}

func embedSourceLikeTeX2img(in doc: PDFDocument, source: String) {
    guard let page = doc.page(at: 0) else { return }
    let annotation = PDFAnnotation(bounds: .zero, forType: .text, withProperties: nil)
    annotation.shouldDisplay = false
    annotation.shouldPrint = false
    annotation.contents = "%%TeX2img Document\n" + source
    page.addAnnotation(annotation)
}

func analyzePDF(at path: String) {
    let data = (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()
    let text = String(data: data, encoding: .isoLatin1) ?? ""
    let version = String(text.prefix(8))
    print("  path           : \(path)")
    print("  size           : \(data.count) bytes")
    print("  header         : \(version)")
    print("  ShadingType 4  : \(text.components(separatedBy: "ShadingType 4").count - 1)")
    print("  PatternType 1  : \(text.components(separatedBy: "PatternType 1").count - 1)")
}

func run() -> Int32 {
    guard let options = parseArgs() else {
        usage()
        return 1
    }

    guard let inputDoc = PDFDocument(url: URL(fileURLWithPath: options.inputPath)) else {
        fputs("error: 入力 PDF を開けません: \(options.inputPath)\n", stderr)
        return 1
    }
    guard let sourcePage = inputDoc.page(at: 0) else {
        fputs("error: ページ 0 がありません\n", stderr)
        return 1
    }

    let outputDoc = PDFDocument()
    let sampleSource = (try? String(contentsOfFile: options.inputPath.replacingOccurrences(of: ".pdf", with: ".tex"))) ?? "% minimal test source"

    switch options.mode {
    case .rewrite:
        outputDoc.insert(sourcePage, at: 0)

    case .crop:
        guard let cropped = cropPageLikeTeX2img(page: sourcePage, pdfPath: options.inputPath, pageNumber: 1) else {
            return 1
        }
        outputDoc.insert(cropped, at: 0)

    case .embed:
        outputDoc.insert(sourcePage, at: 0)
        embedSourceLikeTeX2img(in: outputDoc, source: sampleSource)

    case .cropAndEmbed:
        guard let cropped = cropPageLikeTeX2img(page: sourcePage, pdfPath: options.inputPath, pageNumber: 1) else {
            return 1
        }
        outputDoc.insert(cropped, at: 0)
        embedSourceLikeTeX2img(in: outputDoc, source: sampleSource)

    case .cgDraw:
        try? FileManager.default.removeItem(atPath: options.outputPath)
        guard exportViaCGDraw(page: sourcePage, to: options.outputPath) else {
            fputs("error: CGContext 書き出しに失敗しました\n", stderr)
            return 1
        }
        print("mode: \(options.mode.rawValue)")
        analyzePDF(at: options.outputPath)
        return 0
    }

    try? FileManager.default.removeItem(atPath: options.outputPath)
    guard outputDoc.write(to: URL(fileURLWithPath: options.outputPath)) else {
        fputs("error: 書き出しに失敗しました: \(options.outputPath)\n", stderr)
        return 1
    }

    print("mode: \(options.mode.rawValue)")
    analyzePDF(at: options.outputPath)
    return 0
}

exit(run())