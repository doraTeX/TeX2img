import Cocoa

extension NSPopover {
    convenience init(contentViewController controller: NSViewController) {
        self.init()
        self.contentViewController = controller
        self.behavior = .transient
    }

    func show(atRightOf button: NSButton, view: NSView, offsetX x: CGFloat, y: CGFloat) {
        let rect = button.frame
        let newRect = NSRect(x: rect.origin.x + x,
                             y: rect.origin.y + y,
                             width: rect.size.width,
                             height: rect.size.height)

        show(relativeTo: newRect, of: view, preferredEdge: .maxX)
    }

    @objc class func show(with controller: NSViewController,
                          atRightOf button: NSButton,
                          view: NSView,
                          offsetX x: CGFloat,
                          y: CGFloat) {
        let popover = NSPopover(contentViewController: controller)
        popover.show(atRightOf: button, view: view, offsetX: x,y: y)
    }
}
