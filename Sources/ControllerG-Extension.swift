import Foundation


extension ControllerG {
    @objc func searchProgram(_ programName: String) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = BASH_PATH
        task.arguments = ["-c", "eval `/usr/libexec/path_helper -s`; echo $PATH"];
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        var searchPaths = pipe.stringValue().components(separatedBy: ":")
        
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
            let fullPath = (path as NSString).appendingPathComponent(programName)
            var isDir: ObjCBool = true
            let result = FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
            if result && !isDir.boolValue {
                return fullPath
            }
        }
        
        return nil
    }
}
