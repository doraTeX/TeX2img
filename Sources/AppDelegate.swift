import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var controllerG: ControllerG!
    private var observer: Any!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if #available(macOS 10.14, *) {
            // アウトプットウィンドウだけはライトモード・ダークモードの変更検出を自力でできないので，AppDelegate で変更を検知して ControllerG に対応を依頼する
            self.observer = NSApp.observe(\.effectiveAppearance) { _, _ in
                self.controllerG.refreshOutputTextView(usingProfile: nil)
            }
        }
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return controllerG.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: true)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let filename = filenames.first else { return }
        controllerG.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: false)
    }

}

