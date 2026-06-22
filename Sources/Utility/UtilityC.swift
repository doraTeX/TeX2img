import Foundation

class UtilityC: NSObject {
    private static let whichPath = "/usr/bin/which"
    private static let resourcesDir = "TeX2img.app/Contents/Resources"

    private static func guiPaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Applications"),
            home,
            "/Applications",
            "/Applications/TeXLive",
        ]
    }

    private static func additionalSearchPath() -> String {
        var results = [String]()
        for guiPath in guiPaths() {
            let mupdfPath = guiPath.appendingPathComponent(resourcesDir.appendingPathComponent("mupdf"))
            let pdftopsPath = guiPath.appendingPathComponent(resourcesDir.appendingPathComponent("pdftops"))
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

    static func printStdErr(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }

    static func suggestLatexOption() {
        printStdErr("If you want to use another LaTeX compiler, specify it by using --latex option.\n")
    }

    static func checkWhich(_ cmdName: String) -> Bool {
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

    static func bundledToolPath(_ toolName: String, in subdirectory: String) -> String? {
        let executablePath = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        let executableDirectory = executablePath.deletingLastPathComponent().path
        let candidates = [
            executableDirectory.appendingPathComponent(subdirectory).appendingPathComponent(toolName),
            executableDirectory.appendingPathComponent("../Resources/\(subdirectory)/\(toolName)"),
            executableDirectory.appendingPathComponent("../../Resources/\(subdirectory)/\(toolName)"),
            executableDirectory.appendingPathComponent("TeX2img.app/Contents/Resources/\(subdirectory)/\(toolName)"),
        ]

        for candidate in candidates {
            let standardized = candidate.standardizingPath
            if FileManager.default.isExecutableFile(atPath: standardized) {
                return standardized
            }
        }
        return nil
    }

    static func mudrawPath() -> String? {
        if let path = getPath("mudraw") {
            return path
        }
        return bundledToolPath("mudraw", in: "mupdf")
    }

    static func getPath(_ cmdName: String) -> String? {
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