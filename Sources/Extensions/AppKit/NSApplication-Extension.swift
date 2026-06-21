import AppKit

extension NSApplication {
    @objc public var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return self.effectiveAppearance.isDarkMode
        } else {
            return false
        }
    }
}
