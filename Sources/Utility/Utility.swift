import AppKit
import Foundation
import PDFKit

private let annotationHeader = "%%TeX2img Document\n"
class Utility: NSObject {
    static func execCommand(_ executablePath: String, arguments: [String] = []) -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.arguments = arguments
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        return pipe.stringValue
    }

    static func getFullPath(_ aPath: String) -> String? {
        guard !aPath.isEmpty else { return nil }
        return URL(fileURLWithPath: aPath).standardizedFileURL.path
    }

    static func previewFiles(_ files: [String], app: String) {
        if #available(macOS 10.15, *) {
            let targetURLs = files.map { URL(fileURLWithPath: $0) }
            NSWorkspace.shared.open(targetURLs,
                                    withApplicationAt: URL(fileURLWithPath: app),
                                    configuration: NSWorkspace.OpenConfiguration(),
                                    completionHandler: nil)
        } else {
            for path in files {
                NSWorkspace.shared.openFile(path, withApplication: app)
            }
        }
    }

    static func isTeX2imgAnnotation(_ annotation: PDFAnnotation) -> Bool {
        guard annotation.type == "Text" else { return false }
        let contents = annotation.contents?.replacingOccurrences(of: "\r\n", with: "\n") ?? ""
        return contents.hasPrefix(annotationHeader)
    }
}