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
        let targetURLs = files.map { URL(fileURLWithPath: $0) }
        NSWorkspace.shared.open(targetURLs,
                                withApplicationAt: URL(fileURLWithPath: app),
                                configuration: NSWorkspace.OpenConfiguration(),
                                completionHandler: nil)
    }

    static func openFolderInFinder(_ path: String) {
        guard let finderURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") else { return }
        NSWorkspace.shared.open([URL(fileURLWithPath: path, isDirectory: true)],
                                withApplicationAt: finderURL,
                                configuration: NSWorkspace.OpenConfiguration(),
                                completionHandler: nil)
    }

    static func isTeX2imgAnnotation(_ annotation: PDFAnnotation) -> Bool {
        guard annotation.type == "Text" else { return false }
        let contents = annotation.contents?.replacingOccurrences(of: "\r\n", with: "\n") ?? ""
        return contents.hasPrefix(annotationHeader)
    }
}