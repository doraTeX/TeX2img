import Cocoa

extension NSWindow {
    var isInFullScreenMode: Bool { self.styleMask.contains(.fullScreen) }
}
