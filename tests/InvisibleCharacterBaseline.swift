import AppKit
import ObjectiveC

// Draws invisible characters with the product's MyLayoutManager off screen and checks that every marker
// sits on the baseline and at the drawing origin of the character it stands for (TeXShop's
// Tests/InvisibleCharacterBaseline.m). Also checks the control characters drawn as U+FFFD.
// Run through tests/test_invisible_characters.py.

final class ControllerG: NSObject {
    var markers = ["␣", "□", "↵", "‣"]
    func showTabCharacterEnabled() -> Bool { true }
    func showNewLineCharacterEnabled() -> Bool { true }
    func showFullwidthSpaceCharacterEnabled() -> Bool { true }
    func showSpaceCharacterEnabled() -> Bool { true }
    func spaceCharacter() -> String { markers[0] }
    func fullwidthSpaceCharacter() -> String { markers[1] }
    func returnCharacter() -> String { markers[2] }
    func tabCharacter() -> String { markers[3] }
    func invisibleColor() -> NSColor { .systemRed }
}

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

var expected: [(marker: String, point: NSPoint)] = []
var verified = 0

extension NSLayoutManager {
    @objc dynamic func observedDrawGlyphs(forGlyphRange range: NSRange, at origin: NSPoint) {
        if !(self is MyLayoutManager), let storage = textStorage, storage.length <= 2, !expected.isEmpty {
            let next = expected.removeFirst()
            check(storage.string == next.marker, "the selected marker is drawn (\(storage.string) for \(next.marker))")
            let position = location(forGlyphAt: 0)
            let line = lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
            check(abs(origin.x + line.origin.x + position.x - next.point.x) < 0.01, "horizontal marker position")
            check(abs(origin.y + line.origin.y + position.y - next.point.y) < 0.01, "marker baseline")
            verified += 1
        }
        observedDrawGlyphs(forGlyphRange: range, at: origin)
    }
}

_ = NSApplication.shared
let original = class_getInstanceMethod(NSLayoutManager.self, #selector(NSLayoutManager.drawGlyphs(forGlyphRange:at:)))!
let observed = class_getInstanceMethod(NSLayoutManager.self, #selector(NSLayoutManager.observedDrawGlyphs(forGlyphRange:at:)))!
method_exchangeImplementations(original, observed)

let output = CommandLine.arguments.count > 1 ? URL(fileURLWithPath: CommandLine.arguments[1]) : nil
let image = NSImage(size: NSSize(width: 760, height: 1200))
let choices = [["␣", "·", "°", "ː"], ["□", "■", "•", "⊠"], ["↵", "↩", "⏎", "¶"], ["‣", "▹", "⇥", "¬"]]
let controller = ControllerG()
for variant in 0..<4 {
    controller.markers = choices.map { $0[variant] }
    image.lockFocusFlipped(true)
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: 760, height: 1200).fill()
    for i in 0..<5 {
        let names = ["Menlo-Regular", "HiraginoSans-W3", "Osaka-Mono", "Courier", "SFMono-Regular"]
        let size = CGFloat(14 + 6 * i)
        let font = NSFont(name: names[i], size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = CGFloat(3 * i)
        style.firstLineHeadIndent = 11
        let text = "ABC あいう　XYZ \t終わり\n次の行　 xyz\u{0C}FF\u{01}\n"
        let storage = NSTextStorage(string: text, attributes: [.font: font, .foregroundColor: NSColor.black, .paragraphStyle: style])
        // A different font inside the line: the marker follows it.
        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: size + 5), range: NSRange(location: 7, length: 1))
        let layout = MyLayoutManager(controller: controller)
        let container = NSTextContainer(containerSize: NSSize(width: 690, height: 220))
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        layout.ensureLayout(for: container)
        let origin = NSPoint(x: 23 + CGFloat(i) * 3, y: 20 + CGFloat(i) * 230)
        let laidOut = layout.glyphRange(for: container)
        let string = text as NSString
        check(NSMaxRange(laidOut) == layout.numberOfGlyphs, "a form feed does not hide the rest of the text")
        for glyph in 0..<layout.numberOfGlyphs {
            let character = string.character(at: layout.characterIndexForGlyph(at: glyph))
            let marker: String?
            switch character {
            case 0x20: marker = controller.markers[0]
            case 0x3000: marker = controller.markers[1]
            case 0x0A: marker = controller.markers[2]
            case 0x09: marker = controller.markers[3]
            default: marker = InvisibleCharacters.isShownControlCharacter(character) ? "\u{FFFD}" : nil
            }
            guard let marker else { continue }
            let base = layout.location(forGlyphAt: glyph)
            let line = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            expected.append((marker, NSPoint(x: origin.x + line.origin.x + base.x, y: origin.y + line.origin.y + base.y)))
            if marker == "\u{FFFD}" {
                check(layout.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: container).width > 1,
                      "a control character takes the width of its marker")
            }
        }
        layout.drawGlyphs(forGlyphRange: NSRange(location: 0, length: layout.numberOfGlyphs), at: origin)
        check(expected.isEmpty, "every marker was drawn: left \(expected.map(\.marker)) font \(font.fontName)")
    }
    image.unlockFocus()
}
check(!InvisibleCharacters.isShownControlCharacter(0x09) && !InvisibleCharacters.isShownControlCharacter(0x0A)
      && !InvisibleCharacters.isShownControlCharacter(0x0D) && InvisibleCharacters.isShownControlCharacter(0x0C)
      && InvisibleCharacters.isShownControlCharacter(0x00) && !InvisibleCharacters.isShownControlCharacter(0x20),
      "control characters drawn as U+FFFD: all C0 characters except tab, line feed and carriage return")
if let output, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
    try! rep.representation(using: .png, properties: [:])!.write(to: output)
}
print("PASS: \(verified) marker baselines (five fonts, all marker choices, a mixed font, line spacing, nonzero origins, control characters)")
