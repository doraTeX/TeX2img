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
        // /usr/texbin of earlier profiles becomes /Library/TeX/texbin; other paths and the arguments stay.
        precondition(EnginePathDiscovery.replacingRetiredTeXBin("/usr/texbin/platex -kanji=utf8") == "/Library/TeX/texbin/platex -kanji=utf8")
        precondition(EnginePathDiscovery.replacingRetiredTeXBin("\"/usr/texbin/dvipdfmx\" -vv") == "\"/Library/TeX/texbin/dvipdfmx\" -vv")
        precondition(EnginePathDiscovery.replacingRetiredTeXBin(" /usr/texbin/gs") == " /Library/TeX/texbin/gs")
        for unchanged in ["/usr/texbinx/gs", "/usr/local/bin/gs", "platex /usr/texbin/x", "", "/usr/texbin"] {
            precondition(EnginePathDiscovery.replacingRetiredTeXBin(unchanged) == unchanged, unchanged)
        }
        precondition(!EnginePathDiscovery.systemSearchPaths().contains(EnginePathDiscovery.retiredTeXBin))
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
        // Development builds of TeX Live (TeXShop 6.00): listed by year as the banner names them (not by their folder), after the release of the
        // same year, and the newest release is selected first.
        let devRoot = root.appendingPathComponent("dev")
        let release2026 = try script("dev/2026/bin/universal-darwin", "uplatex", "echo 'e-upTeX 3.141592653-p4.1.0-u1.30-2.6 (utf8.uptex) (TeX Live 2026)'")
        let dev2027 = try script("dev/2027/bin/universal-darwin", "uplatex", "echo 'e-upTeX 3.141592653-p4.1.1-u1.31-2.6 (utf8.uptex) (TeX Live 2027/dev)'")
        let dev2026 = try script("dev/2028/bin/universal-darwin", "uplatex", "echo 'e-upTeX 3.141592653-p4.1.0-u1.30-2.6 (utf8.uptex) (TeX Live 2026/dev)'")
        let devFound = EnginePathDiscovery.candidates(program: "uplatex", paths: EnginePathDiscovery.texLivePaths(roots: [devRoot.path]))
        precondition(devFound.map(\.path) == [dev2027, release2026, dev2026], "\(devFound.map(\.path))")
        precondition(devFound[0].label.hasPrefix("TeX Live 2027/dev ") && devFound[0].dev && !devFound[1].dev, devFound[0].label)
        precondition(devFound[1].label.hasPrefix("TeX Live 2026 3.141592653"), devFound[1].label)
        precondition(EnginePathDiscovery.preselectedIndex(devFound) == 1, "the newest release is selected")
        // Only development builds: the newest of them.
        precondition(EnginePathDiscovery.preselectedIndex([devFound[0], devFound[2]]) == 0)
        // A distributor's name is not a development build, and only the banner line names the release.
        precondition(EnginePathDiscovery.release(inBanner: "pdfTeX 3.14 (TeX Live 2026/dev-tools)")?.dev == false)
        precondition(EnginePathDiscovery.release(inBanner: "pdfTeX 3.14 (TeX Live 2026/Debian)").map { ($0.name, $0.dev) } ?? ("", true) == ("TeX Live 2026", false))
        precondition(EnginePathDiscovery.release(inBanner: "pdfTeX 3.14 (Web2C 2027/dev)").map { ($0.name, $0.year, $0.dev) } ?? ("", 0, false) == ("Web2C 2027/dev", 2027, true))
        precondition(EnginePathDiscovery.release(inBanner: "pdfTeX 3.14 (TeX Live 2026)\nLocal wrapper for TeX Live 2030")?.year == 2026)
        precondition(EnginePathDiscovery.release(inBanner: "This is dvipdfmx Version 20240305") == nil)
        precondition(EnginePathDiscovery.release(inBanner: "\nThis is dvipdfmx Version 20240305\nwrapped for TeX Live 2030") == nil,
                     "a release named after the banner line is not taken")
        // A wrapper that prints its own words before the engine's banner, with a year of its own or none: the version, the
        // release and whether it is a development build come from the engine's line only.
        let wrapperRoot = root.appendingPathComponent("wrapped")
        let wrappedRelease = try script("wrapped/2026/bin/universal-darwin", "uplatex",
            "printf 'Local wrapper for TeX Live 2030\\ne-upTeX 3.141592653-p4.1.0-u1.30-2.6 (utf8.uptex) (TeX Live 2026)\\nkpathsea version 6.4.0\\n'")
        let wrappedDev = try script("wrapped/2027/bin/universal-darwin", "uplatex",
            "printf 'Local wrapper for TeX Live 2030\\ne-upTeX 3.14 (TeX Live 2027/dev)\\n'")
        let wrappedNoYear = try script("wrapped/2025/bin/universal-darwin", "uplatex",
            "printf 'Wrapper started\\ne-upTeX 3.141592653-p4.1.0-u1.29-2.6 (utf8.uptex) (TeX Live 2025)\\n'")
        let wrappedVersioned = try script("wrapped/2024/bin/universal-darwin", "uplatex",
            "printf 'TeXWrapper 2.0 for TeX Live 2030\\ne-upTeX 3.141592653-p4.1.0-u1.29-2.6 (utf8.uptex) (TeX Live 2024/dev)\\n'")
        let wrapped = EnginePathDiscovery.candidates(program: "uplatex", paths: EnginePathDiscovery.texLivePaths(roots: [wrapperRoot.path]))
        precondition(wrapped.map(\.path) == [wrappedDev, wrappedRelease, wrappedNoYear, wrappedVersioned], "\(wrapped.map(\.path))")
        precondition(wrapped[3].label.hasPrefix("TeX Live 2024/dev 3.141592653") && wrapped[3].dev,
                     "a wrapper with a version of its own is not the engine: \(wrapped[3].label)")
        precondition(EnginePathDiscovery.bannerLine(in: "TeXWrapper 2.0 for TeX Live 2030\ne-upTeX 3.14 (TeX Live 2027/dev)\n") == "e-upTeX 3.14 (TeX Live 2027/dev)")
        precondition(EnginePathDiscovery.bannerLine(in: "LaTeXWrap 1.0\nThis is TeX, Version 3.141592653 (TeX Live 2026)\n") == "This is TeX, Version 3.141592653 (TeX Live 2026)")
        precondition(wrapped[0].label.hasPrefix("TeX Live 2027/dev 3.14 — ") && wrapped[0].dev, wrapped[0].label)
        precondition(wrapped[1].label.hasPrefix("TeX Live 2026 3.141592653") && wrapped[2].label.hasPrefix("TeX Live 2025 3.141592653"),
                     "\(wrapped[1].label) \(wrapped[2].label)")
        precondition(EnginePathDiscovery.preselectedIndex(wrapped) == 1, "the release 2026 is selected, not the wrapper's year")
        for banner in ["This is LuaHBTeX, Version 1.18.0 (TeX Live 2026)", "This is dvips(k) 2026.1 (TeX Live 2026)  Copyright",
                       "This is dvipdfmx Version 20260305 by the DVIPDFMx project team,", "pdfTeX 3.141592653-2.6-1.40.28 (TeX Live 2026)"] {
            precondition(EnginePathDiscovery.bannerLine(in: "pdfTeX wrapper: Local build for TeX Live 2099\n" + banner + "\n") == banner, banner)
        }
        print("Engine discovery regression tests passed")
    }
}
