import AppKit
import Foundation
import PDFKit

private let annotationHeader = "%%TeX2img Document\n"
private let bashPath = "/bin/bash"

@objc(Utility)
class Utility: NSObject {
    @objc static func execCommand(_ cmdline: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: bashPath)
        task.arguments = ["-c", cmdline]
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        return pipe.stringValue
    }

    @objc static func getFullPath(_ aPath: String) -> String? {
        let url = NSURL(fileURLWithPath: aPath)
        return (String(cString: url.fileSystemRepresentation) as NSString).standardizingPath
    }

    @objc static func previewFiles(_ files: [String], app: String) {
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

    @objc static func isTeX2imgAnnotation(_ annotation: PDFAnnotation) -> Bool {
        guard annotation.type == "Text" else { return false }
        let contents = annotation.contents?.replacingOccurrences(of: "\r\n", with: "\n") ?? ""
        return contents.hasPrefix(annotationHeader)
    }
}