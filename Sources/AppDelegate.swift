import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var controllerG: ControllerG!
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return controllerG.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: true)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let filename = filenames.first else { return }
        controllerG.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: false)
    }

}

