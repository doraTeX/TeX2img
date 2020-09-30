import Cocoa
import UserNotifications


extension ControllerG {
    @objc func sendUserNotification(status: ExitStatus) {
        let title: String
        guard let body = (self.currentProfile()["outputFile"] as? NSString)?.lastPathComponent else { return }
        
        switch status {
        case .failed:
            title = NSLocalizedString("Failed", comment: "")
        case .aborted:
            title = NSLocalizedString("Aborted", comment: "")
        default:
            title = NSLocalizedString("Completed", comment: "")
        }
        
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert]) { (_, _) in }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        } else {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = body
            
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    public func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
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
                searchPaths += years.map { (path as NSString).replacingOccurrences(of: "XXXX", with: String($0))}
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



@available(macOS 10.14, *)
extension ControllerG {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .alert, .badge])
    }
}

