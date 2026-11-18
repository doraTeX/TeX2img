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

    /// Whether two paths name the same file, however they are written (/tmp and /private/tmp, symbolic links to
    /// folders, ".."). A symbolic link at the end of a path is a file of its own: replacing it leaves its target.
    static func isSameFile(_ path1: String, _ path2: String) -> Bool {
        var status1 = stat()
        var status2 = stat()
        guard lstat(path1, &status1) == 0, lstat(path2, &status2) == 0 else { return false }
        return status1.st_dev == status2.st_dev && status1.st_ino == status2.st_ino
    }

    /// Whether writing the output path would replace the input. The output path is replaced as it is (a symbolic
    /// link there is replaced, not its target); the input counts as the path itself and as the file that it reads
    /// through symbolic links (alias.pdf → out.pdf: writing out.pdf replaces what alias.pdf is).
    static func outputReplacesInput(output: String, input: String) -> Bool {
        var outputStatus = stat()
        guard lstat(output, &outputStatus) == 0 else { return false }
        var inputStatus = stat()
        if lstat(input, &inputStatus) == 0 && inputStatus.st_dev == outputStatus.st_dev && inputStatus.st_ino == outputStatus.st_ino {
            return true
        }
        return stat(input, &inputStatus) == 0 && inputStatus.st_dev == outputStatus.st_dev && inputStatus.st_ino == outputStatus.st_ino
    }

    /// The process group of a launched command: Process makes the command the leader of a group of its own. 0 if it
    /// is not (then only the command itself can be stopped).
    static func processGroup(of task: Process) -> pid_t {
        let pid = task.processIdentifier
        guard pid > 1 else { return 0 }
        let group = getpgid(pid)
        return group == pid && group != getpgrp() ? group : 0
    }

    /// Stops a command and everything it started, as TeXShop's stopJobTask does: SIGTERM to its process group, up to
    /// 0.5 s for them to end, then SIGKILL to whatever remains. A program that ignores SIGTERM (one that TeX runs by
    /// shell escape, say) is stopped too, also when the shell has already ended. The group is the one recorded at
    /// launch; it is not signalled if it is gone or is TeX2img's own.
    static func stopCommand(_ task: Process, group recorded: pid_t) {
        let group = recorded > 1 && recorded != getpgrp() && kill(-recorded, 0) == 0 ? recorded : 0
        if group > 0 {
            kill(-group, SIGTERM)
        } else if task.isRunning {
            task.terminate()
        }
        let start = Date()
        while (task.isRunning || (group > 0 && kill(-group, 0) == 0)) && Date().timeIntervalSince(start) < 0.5 {
            usleep(10_000)
        }
        if group > 0 && kill(-group, 0) == 0 {
            kill(-group, SIGKILL)
        }
        if task.isRunning && task.processIdentifier > 1 {
            kill(task.processIdentifier, SIGKILL)
        }
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