import AppKit
import Foundation
import PDFKit

func analyze(_ path: String) -> String {
    let data = (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()
    let text = String(data: data, encoding: .isoLatin1) ?? ""
    return String(format: "%@  ver=%@  S4=%4d  P1=%4d  bytes=%d",
                  (path as NSString).lastPathComponent,
                  String(text.prefix(8)),
                  text.components(separatedBy: "ShadingType 4").count - 1,
                  text.components(separatedBy: "PatternType 1").count - 1,
                  data.count)
}

let input = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]
guard let doc = PDFDocument(url: URL(fileURLWithPath: input)) else {
    fputs("cannot open input\n", stderr)
    exit(1)
}

print("input  major=\(doc.majorVersion) minor=\(doc.minorVersion)")
print(analyze(input))

struct Case {
    let name: String
    let options: [PDFDocumentWriteOption: Any]?
    let useDataRepresentation: Bool
}

// Undocumented keys found in PDFKit.tbd (private SPI — may be ignored)
let saveWithCorePDFLayout = "SaveWithCorePDFLayout" as PDFDocumentWriteOption
let useAppendMode = "UseAppendMode" as PDFDocumentWriteOption

let cases: [Case] = [
    Case(name: "write-default", options: nil, useDataRepresentation: false),
    Case(name: "dataRepresentation", options: nil, useDataRepresentation: true),
    Case(name: "burnInAnnotations", options: [.burnInAnnotations: true], useDataRepresentation: false),
    Case(name: "saveWithCorePDFLayout", options: [saveWithCorePDFLayout: true], useDataRepresentation: false),
    Case(name: "useAppendMode", options: [useAppendMode: true], useDataRepresentation: false),
    Case(name: "corepdf-plus-append", options: [saveWithCorePDFLayout: true, useAppendMode: true], useDataRepresentation: false),
]

for testCase in cases {
    let out = (outDir as NSString).appendingPathComponent("\(testCase.name).pdf")
    try? FileManager.default.removeItem(atPath: out)

    let ok: Bool
    if testCase.useDataRepresentation {
        if let data = doc.dataRepresentation() {
            ok = (try? data.write(to: URL(fileURLWithPath: out))) != nil
        } else {
            ok = false
        }
    } else if let options = testCase.options {
        ok = doc.write(to: URL(fileURLWithPath: out), withOptions: options)
    } else {
        ok = doc.write(to: URL(fileURLWithPath: out))
    }

    print(ok ? analyze(out) : "\(testCase.name): FAILED")
}