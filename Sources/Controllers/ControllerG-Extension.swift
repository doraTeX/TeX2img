import Foundation


extension ControllerG {
    func searchProgram(_ programName: String) -> String? {
        var searchPaths = Self.pathHelperSearchPaths()
        
        let additionalPaths = [
            "/Applications/TeXLive/Library/mactexaddons/bin",
            "/Applications/TeXLive/Library/texlive/XXXX/bin/YYYY",
            "/Applications/TeXLive/texlive/XXXX/bin/YYYY",
            "/usr/local/texlive/XXXX/bin/YYYY",
            "/opt/texlive/XXXX/bin/YYYY",
            "/Library/TeX/texbin",
            "/usr/texbin",
            "/Applications/UpTeX.app/Contents/Resources/TEX/texbin/",
            "/Applications/UpTeX.app/Contents/Resources/texbin/",
            "/Applications/UpTeX.app/teTeX/bin",
            "/Applications/pTeX.app/teTeX/bin",
            "/usr/local/teTeX/bin",
            "/usr/local/bin",
            "/opt/local/bin",
            "/sw/bin"
        ]
        
        let years = Array((2013..<2100).reversed())
        let platforms = ["x86_64-darwin", "x86_64-darwinlegacy", "universal-darwin"]
        
        for path in additionalPaths {
            if path.contains("XXXX") {
                for year in years {
                    let replacedPath = path.replacingOccurrences(of: "XXXX", with: String(year))
                    if replacedPath.contains("YYYY") {
                        for platform in platforms {
                            searchPaths.append(replacedPath.replacingOccurrences(of: "YYYY", with: platform))
                        }
                    } else {
                        searchPaths.append(replacedPath)
                    }
                }
            } else {
                searchPaths.append(path)
            }
        }
        
        for path in searchPaths {
            let fullPath = path.appendingPathComponent(programName)
            if FileManager.default.isRegularFile(atPath: fullPath) {
                return fullPath
            }
        }

        return nil
    }

    private static func pathHelperSearchPaths() -> [String] {
        var paths = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":") ?? []

        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/libexec/path_helper")
        task.arguments = ["-s"]
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()

        let output = pipe.stringValue
        if let range = output.range(of: #"PATH="([^"]+)""#, options: .regularExpression) {
            let match = output[range]
            let pathString = match.dropFirst(5).dropLast()
            paths.insert(contentsOf: pathString.split(separator: ":").map(String.init), at: 0)
        }

        return paths
    }
}
