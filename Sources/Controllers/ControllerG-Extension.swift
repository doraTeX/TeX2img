import Foundation
import Darwin

// Mirrors TeXShop's TSEnginePathDiscovery, adapted to individual TeX2img commands.
enum EnginePathDiscovery {
    struct Candidate {
        let path: String
        let version: String
        let year: Int
        var label: String {
            let description = year > 0 ? "TeX Live \(year) \(version)" : version
            return "\(description.isEmpty ? "?" : description) — \(path)"
        }
    }

    static func texLivePaths(roots: [String]) -> [String] {
        #if arch(arm64)
        let platforms = ["universal-darwin", "arm64-darwin", "x86_64-darwin", "x86_64-darwinlegacy"]
        #else
        let platforms = ["universal-darwin", "x86_64-darwin", "x86_64-darwinlegacy"]
        #endif
        return roots.flatMap { root in
            let years = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
            return years.filter { $0.count == 4 && $0.allSatisfy(\.isNumber) }
                .sorted { $0.compare($1, options: .numeric) == .orderedDescending }
                .flatMap { year in platforms.map { "\(root)/\(year)/bin/\($0)" } }
        }
    }

    static func normalizedPaths(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        return paths.compactMap {
            let expanded = ($0.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
            guard (expanded as NSString).isAbsolutePath else { return nil }
            let path = (expanded as NSString).standardizingPath
            return seen.insert(path).inserted ? path : nil
        }
    }

    static func systemSearchPaths() -> [String] {
        let files = ["/etc/paths"] + ((try? FileManager.default.contentsOfDirectory(atPath: "/etc/paths.d")) ?? [])
            .sorted().map { "/etc/paths.d/\($0)" }
        var paths = files.flatMap { ((try? String(contentsOfFile: $0, encoding: .utf8)) ?? "").components(separatedBy: .newlines) }
        paths += (ProcessInfo.processInfo.environment["PATH"] ?? "").components(separatedBy: ":")
        paths += ["/Library/TeX/texbin", "/usr/texbin", "/Applications/TeXLive/Library/mactexaddons/bin"]
        paths += texLivePaths(roots: ["/Applications/TeXLive", "/Applications/TeXLive/Library/texlive", "/Applications/TeXLive/texlive", "/usr/local/texlive", "/opt/texlive"])
        paths += ["/Applications/UpTeX.app/Contents/Resources/TEX/texbin", "/Applications/UpTeX.app/Contents/Resources/texbin", "/Applications/UpTeX.app/teTeX/bin", "/Applications/pTeX.app/teTeX/bin", "/usr/local/teTeX/bin", "/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin", "/sw/bin"]
        return normalizedPaths(paths)
    }

    static func isExecutable(_ path: String) -> Bool {
        var directory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &directory) && !directory.boolValue && FileManager.default.isExecutableFile(atPath: path)
    }

    // Never invoke a shell; bound runtime and output even for broken/custom executables.
    static func versionOutput(_ path: String, timeout: TimeInterval = 2) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["--version"]
        task.standardInput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        task.standardOutput = pipe
        do { try task.run() } catch { return nil }
        defer {
            pipe.fileHandleForReading.closeFile()
            pipe.fileHandleForWriting.closeFile()
        }
        let fd = pipe.fileHandleForReading.fileDescriptor
        guard fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK) != -1 else {
            kill(task.processIdentifier, SIGKILL)
            task.waitUntilExit()
            return nil
        }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var failed = false
        repeat {
            let exited = !task.isRunning
            while true {
                let count = read(fd, &buffer, buffer.count)
                if count <= 0 { break }
                if data.count + count > 65536 || ProcessInfo.processInfo.systemUptime > deadline {
                    failed = true
                    break
                }
                data.append(contentsOf: buffer.prefix(count))
            }
            if ProcessInfo.processInfo.systemUptime > deadline { failed = true }
            if failed || exited { break }
            Thread.sleep(forTimeInterval: 0.01)
        } while true
        if task.isRunning { kill(task.processIdentifier, SIGKILL) }
        task.waitUntilExit()
        guard !failed, task.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func capture(_ pattern: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return "" }
        return String(text[range])
    }

    static func candidates(program: String, paths: [String], currentDirectory: String = "") -> [Candidate] {
        guard !program.isEmpty, !program.contains("/") else { return [] }
        var seen = Set<String>()
        var matches: [(Int, Candidate)] = []
        let preferred = paths.contains("/Library/TeX/texbin") ? ["/Library/TeX/texbin"] : []
        for directory in normalizedPaths(preferred + [currentDirectory] + paths) {
            let path = (directory as NSString).appendingPathComponent(program)
            guard isExecutable(path) else { continue }
            let identity = (path as NSString).resolvingSymlinksInPath
            guard !seen.contains(identity), let output = versionOutput(path) else { continue }
            seen.insert(identity)
            let year = Int(capture("TeX Live ([0-9]{4})", in: output)) ?? 0
            let version = capture(program == "gs" ? #"^\s*([0-9]+(?:\.[0-9]+)+)"# : #"^[^\n]*?\s([0-9]+(?:[.\-][0-9]+)*)"#, in: output)
            matches.append((matches.count, Candidate(path: path, version: version, year: year)))
        }
        return matches.sorted { a, b in
            let ak = a.1.year > 0 || !a.1.version.isEmpty, bk = b.1.year > 0 || !b.1.version.isEmpty
            if ak != bk { return ak }
            if a.1.year != b.1.year { return a.1.year > b.1.year }
            let order = a.1.version.compare(b.1.version, options: .numeric)
            return order == .orderedSame ? a.0 < b.0 : order == .orderedDescending
        }.map { $0.1 }
    }
}
