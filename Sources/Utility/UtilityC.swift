import Foundation

@objc(UtilityC)
class UtilityC: NSObject {
    private static let whichPath = "/usr/bin/which"
    private static let resourcesDir = "TeX2img.app/Contents/Resources"

    private static func guiPaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            (home as NSString).appendingPathComponent("Desktop"),
            (home as NSString).appendingPathComponent("Applications"),
            home,
            "/Applications",
            "/Applications/TeXLive",
        ]
    }

    private static func additionalSearchPath() -> String {
        var results = [String]()
        for guiPath in guiPaths() {
            let mupdfPath = (guiPath as NSString).appendingPathComponent((resourcesDir as NSString).appendingPathComponent("mupdf"))
            let pdftopsPath = (guiPath as NSString).appendingPathComponent((resourcesDir as NSString).appendingPathComponent("pdftops"))
            results.append(mupdfPath)
            results.append(pdftopsPath)
        }
        return results.joined(separator: ":")
    }

    private static func processEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let additional = additionalSearchPath()
        let currentPath = environment["PATH"] ?? ""
        environment["PATH"] = "\(additional):\(currentPath)"
        return environment
    }

    @objc static func printStdErr(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }

    @objc static func suggestLatexOption() {
        printStdErr("If you want to use another LaTeX compiler, specify it by using --latex option.\n")
    }

    @objc static func checkWhich(_ cmdName: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: whichPath)
        task.arguments = [cmdName]
        task.environment = processEnvironment()
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }

    @objc static func getPath(_ cmdName: String) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: whichPath)
        task.arguments = [cmdName]
        task.environment = processEnvironment()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return nil }
        let output = pipe.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return output.isEmpty ? nil : output
    }
}