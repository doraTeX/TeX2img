import AppKit

extension NSAppearance {
    @objc public var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return self.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            return false
        }
    }
}

