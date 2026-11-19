import Cocoa

/// NSFont and NSColor are classes, so a non-optional value can still be a null pointer.
/// addAttribute:value:range: raises NSInvalidArgumentException when that pointer is nil.
@inline(never)
@_optimize(none)
private func liveInstance<T: AnyObject>(_ object: T?) -> T? { object }

extension NSMatrix {
    func setCellColor(_ color: NSColor) {
        guard let color = liveInstance(color) else { return }
        for case let cell as NSButtonCell in self.cells {
            let title = NSMutableAttributedString(attributedString: cell.attributedTitle)

            title.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: 0, length: title.length))

            cell.attributedTitle = title
        }
    }

    func setCellFont(_ font: NSFont) {
        guard let font = liveInstance(font) else { return }
        for case let cell as NSButtonCell in self.cells {
            let title = NSMutableAttributedString(attributedString: cell.attributedTitle)

            title.addAttribute(
                .font,
                value: font,
                range: NSRange(location: 0, length: title.length))

            cell.attributedTitle = title
        }
    }
}
