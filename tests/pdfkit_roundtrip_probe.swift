// PDFKitの保存経路を比較する調査用プローブ。入力PDFと出力先ディレクトリを指定する。
import AppKit
import PDFKit
let input = CommandLine.arguments[1]
let dir = CommandLine.arguments[2]
for mode in ["direct", "data", "insert", "crop", "embed", "embed-flags", "cg", "select", "page-data"] {
    let doc = PDFDocument(url: URL(fileURLWithPath: input))!
    let page = doc.page(at: 0)!
    let out = URL(fileURLWithPath: dir + "/" + mode + ".pdf")
    var success = false
    switch mode {
    case "data": success = (try? doc.dataRepresentation()!.write(to: out)) != nil
    case "insert":
        let other = PDFDocument(); other.insert(page, at: 0); success = other.write(to: out)
    case "crop":
        let box = page.bounds(for: .mediaBox).insetBy(dx: -10, dy: -10)
        page.setBounds(box, for: .mediaBox); page.setBounds(box, for: .cropBox)
        success = doc.write(to: out)
    case "embed", "embed-flags":
        let annot = PDFAnnotation(bounds: .zero, forType: .text, withProperties: nil)
        annot.contents = "%%TeX2img Document\n日本語の原稿\\[x^2\\]"
        annot.shouldDisplay = false; annot.shouldPrint = false
        page.addAnnotation(annot)
        success = mode == "embed" ? doc.write(to: out) : doc.write(to: out, withOptions: [.burnInAnnotationsOption:false])
    case "select":
        for index in (0..<doc.pageCount).reversed() { if index != 0 { doc.removePage(at: index) } }
        success = doc.write(to: out)
    case "page-data": success = (try? page.dataRepresentation!.write(to: out)) != nil
    case "cg":
        var box = page.bounds(for: .mediaBox)
        let context = CGContext(out as CFURL, mediaBox: &box, nil)!
        context.beginPDFPage(nil); context.drawPDFPage(page.pageRef!); context.endPDFPage(); context.closePDF(); success = true
    default: success = doc.write(to: out)
    }
    let data = try! Data(contentsOf: out)
    let s = String(decoding: data, as: UTF8.self)
    print(mode, success, data.count, "S4", s.components(separatedBy:"ShadingType 4").count-1,"P1",s.components(separatedBy:"PatternType 1").count-1)
}
