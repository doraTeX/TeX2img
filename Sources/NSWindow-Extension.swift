import Cocoa

extension NSWindow {
    @objc var isInFullScreenMode: Bool { self.styleMask.contains(.fullScreen) }
}
