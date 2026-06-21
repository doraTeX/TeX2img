import Cocoa

class AutoSelectTextField: NSTextField {
    override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        if let textEditor = currentEditor() {
            textEditor.selectAll(self)
        }
    }
}
