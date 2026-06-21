import AppKit

extension NSColorWell {
    func saveColor(to dictionary: inout [String: Any]) {
        dictionary[description] = color
    }

    func restoreColor(from dictionary: [String: Any]) {
        if let color = dictionary[description] as? NSColor {
            self.color = color
        }
    }
}