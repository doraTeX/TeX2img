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
            "/Applications/TeXLive/Library/texlive/XXXX/bin/x86_64-darwin",
            "/Applications/TeXLive/texlive/XXXX/bin/x86_64-darwin",
            "/usr/local/texlive/XXXX/bin/x86_64-darwin",
            "/opt/texlive/XXXX/bin/x86_64-darwin",
            "/Applications/TeXLive/Library/texlive/XXXX/bin/x86_64-darwinlegacy",
            "/Applications/TeXLive/Library/texlive/XXXX/bin/universal-darwin",
            "/Applications/TeXLive/texlive/XXXX/bin/x86_64-darwinlegacy",
            "/Applications/TeXLive/texlive/XXXX/bin/universal-darwin",
            "/usr/local/texlive/XXXX/bin/x86_64-darwinlegacy",
            "/usr/local/texlive/XXXX/bin/universal-darwin",
            "/opt/local/texlive/XXXX/bin/universal-darwin",
            "/opt/texlive/XXXX/bin/x86_64-darwinlegacy",
            "/opt/texlive/XXXX/bin/universal-darwin",
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
        
        for path in additionalPaths {
            if path.contains("XXXX") {
                searchPaths += years.map { path.replacingOccurrences(of: "XXXX", with: String($0))}
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
