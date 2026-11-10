import AppKit

@main
struct EngineDiscoveryRegression {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        func script(_ directory: String, _ name: String, _ body: String, executable: Bool = true) throws -> String {
            let dir = root.appendingPathComponent(directory)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            let path = dir.appendingPathComponent(name)
            try ("#!/bin/sh\n" + body + "\n").write(to: path, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: executable ? 0o755 : 0o644], ofItemAtPath: path.path)
            return path.path
        }
        let old = try script("old", "gs", "echo 9.56.1")
        let new = try script("new", "gs", "echo 10.04.0")
        let unknown = try script("unknown", "gs", "echo custom")
        let failed = try script("failed", "gs", "exit 1")
        let nonexec = try script("nonexec", "gs", "echo 99.0", executable: false)
        let alias = root.appendingPathComponent("alias")
        try fm.createSymbolicLink(atPath: alias.path, withDestinationPath: root.appendingPathComponent("new").path)
        let paths = [old, unknown, failed, nonexec, new].map { ($0 as NSString).deletingLastPathComponent } + [alias.path]
        let found = EnginePathDiscovery.candidates(program: "gs", paths: paths)
        precondition(found.map(\.path) == [new, old, unknown])
        precondition(EnginePathDiscovery.normalizedPaths(["", ".", "relative", "/tmp", "/tmp/../tmp"]) == ["/tmp"])
        let stuck = try script("stuck", "gs", "while :; do :; done")
        let start = ProcessInfo.processInfo.systemUptime
        precondition(EnginePathDiscovery.versionOutput(stuck, timeout: 0.1) == nil)
        precondition(ProcessInfo.processInfo.systemUptime - start < 2)
        let flood = try script("flood", "gs", "while :; do echo '012345678901234567890123456789'; done")
        precondition(EnginePathDiscovery.versionOutput(flood) == nil)
        let badUTF8 = try script("utf8", "gs", "printf '\\377'")
        precondition(EnginePathDiscovery.versionOutput(badUTF8) == nil)
        let texOld = try script("2025/bin/universal-darwin", "latex", "echo 'pdfTeX 3.141592653-2.6-1.40.27 (TeX Live 2025)'")
        let texNew = try script("2026/bin/universal-darwin", "latex", "echo 'pdfTeX 3.141592653-2.6-1.40.28 (TeX Live 2026)'")
        let texPaths = EnginePathDiscovery.texLivePaths(roots: [root.path])
        precondition(EnginePathDiscovery.candidates(program: "latex", paths: texPaths).map(\.path) == [texNew, texOld])
        let dviOld = try script("old", "dvipdfmx", "echo 'This is dvipdfmx Version 20240305'")
        let dviNew = try script("new", "dvipdfmx", "echo 'This is dvipdfmx Version 20260305'")
        precondition(EnginePathDiscovery.candidates(program: "dvipdfmx", paths: paths).map(\.path) == [dviNew, dviOld])
        print("Engine discovery regression tests passed")
    }
}
