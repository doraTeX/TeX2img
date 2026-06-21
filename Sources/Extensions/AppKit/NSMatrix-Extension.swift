import Cocoa

extension NSMatrix {
    @objc func setCellColor(_ color: NSColor) {
        for case let cell as NSButtonCell in self.cells {
            let title = NSMutableAttributedString(attributedString: cell.attributedTitle)

            title.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: 0, length: title.length))

            cell.attributedTitle = title
        }
    }

    @objc func setCellFont(_ font: NSFont) {
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
