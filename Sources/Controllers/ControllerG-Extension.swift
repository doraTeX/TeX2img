import Foundation
import Darwin

// Mirrors TeXShop's TSEnginePathDiscovery, adapted to individual TeX2img commands.
enum EnginePathDiscovery {
    struct Candidate {
        let path: String
        let version: String
        let year: Int
        /// The release as the banner names it ("TeX Live 2027/dev", "Web2C 2026"), and whether it is a development build
        /// (TeXShop 6.00).
        var release: String = ""
        var dev: Bool = false
        var label: String {
            let name = release.isEmpty ? (year > 0 ? "TeX Live \(year)" : "") : release
            let description = [name, version].filter { !$0.isEmpty }.joined(separator: " ")
            return "\(description.isEmpty ? "?" : description) — \(path)"
        }
    }

    /// The release named in a --version banner (its first line): name, year and whether it is a development build; nil when
    /// none. Between releases the sources say "YYYY/dev"; distributors may append "/Name". Builds outside TeX Live say
    /// "Web2C". "dev" counts only as a whole component, so that "/dev-tools" stays a distributor's name (TeXShop 6.00).
    static func release(inBanner output: String) -> (name: String, year: Int, dev: Bool)? {
        let line = output.components(separatedBy: .newlines).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
        guard let regex = try? NSRegularExpression(pattern: #"(?:TeX Live|Web2C) ([0-9]{4})(/dev(?=[/)\s]|$))?"#),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let whole = Range(match.range, in: line), let year = Range(match.range(at: 1), in: line) else { return nil }
        return (String(line[whole]), Int(line[year]) ?? 0, match.range(at: 2).location != NSNotFound)
    }

    /// The candidate to select first: the newest release a banner names; without one, the first (TeXShop 6.00).
    static func preselectedIndex(_ candidates: [Candidate]) -> Int {
        candidates.firstIndex { $0.year > 0 && !$0.dev } ?? 0
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

    static let texBin = "/Library/TeX/texbin"
    /// The link of MacTeX before OS X 10.11, which cannot exist on the macOS versions TeX2img runs on.
    static let retiredTeXBin = "/usr/texbin"

    /// A command saved with /usr/texbin runs from /Library/TeX/texbin instead, as TeXShop 6.00 does at launch.
    /// The arguments, and a quote around the command, stay as they are.
    static func replacingRetiredTeXBin(_ command: String) -> String {
        let leading = command.prefix { $0 == " " || $0 == "\t" }
        var rest = command.dropFirst(leading.count)
        var quote = ""
        if let first = rest.first, first == "\"" || first == "'" {
            quote = String(first)
            rest = rest.dropFirst()
        }
        guard rest.hasPrefix(retiredTeXBin + "/") else { return command }
        return leading + quote + texBin + rest.dropFirst(retiredTeXBin.count)
    }

    static func systemSearchPaths() -> [String] {
        let files = ["/etc/paths"] + ((try? FileManager.default.contentsOfDirectory(atPath: "/etc/paths.d")) ?? [])
            .sorted().map { "/etc/paths.d/\($0)" }
        var paths = files.flatMap { ((try? String(contentsOfFile: $0, encoding: .utf8)) ?? "").components(separatedBy: .newlines) }
        paths += (ProcessInfo.processInfo.environment["PATH"] ?? "").components(separatedBy: ":")
        paths += [texBin, "/Applications/TeXLive/Library/mactexaddons/bin"]
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
        let preferred = paths.contains(texBin) ? [texBin] : []
        for directory in normalizedPaths(preferred + [currentDirectory] + paths) {
            let path = (directory as NSString).appendingPathComponent(program)
            guard isExecutable(path) else { continue }
            let identity = (path as NSString).resolvingSymlinksInPath
            guard !seen.contains(identity), let output = versionOutput(path) else { continue }
            seen.insert(identity)
            let release = program == "gs" ? nil : release(inBanner: output)
            let version = capture(program == "gs" ? #"^\s*([0-9]+(?:\.[0-9]+)+)"# : #"^[^\n]*?\s([0-9]+(?:[.\-][0-9]+)*)"#, in: output)
            matches.append((matches.count, Candidate(path: path, version: version, year: release?.year ?? 0,
                                                     release: release?.name ?? "", dev: release?.dev ?? false)))
        }
        return matches.sorted { a, b in
            let ak = a.1.year > 0 || !a.1.version.isEmpty, bk = b.1.year > 0 || !b.1.version.isEmpty
            if ak != bk { return ak }
            if a.1.year != b.1.year { return a.1.year > b.1.year }
            // "YYYY/dev" is the trunk before the YYYY release, so it is older than that release.
            if a.1.dev != b.1.dev { return b.1.dev }
            let order = a.1.version.compare(b.1.version, options: .numeric)
            return order == .orderedSame ? a.0 < b.0 : order == .orderedDescending
        }.map { $0.1 }
    }
}
