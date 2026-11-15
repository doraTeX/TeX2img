import AppKit

// Builds Character Info (MyGlyphPopoverController) off screen and checks what it shows, its counts and its layout,
// as TeXShop 6.00's Tests/GlyphPopover.m does. No window is shown. Run through tests/test_glyph_popover.py.

func check(_ condition: Bool, _ message: String) {
    if !condition {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

func all<T>(_ type: T.Type, in view: NSView) -> [T] {
    ((view as? T).map { [$0] } ?? []) + view.subviews.flatMap { all(type, in: $0) }
}

func view(_ identifier: String, in root: NSView) -> NSView? {
    all(NSView.self, in: root).first { $0.identifier?.rawValue == identifier }
}

func text(_ identifier: String, in root: NSView) -> String? {
    (view(identifier, in: root) as? NSTextField)?.stringValue
}

/// Every label shows its whole text and stays inside the popover.
func checkLayout(_ controller: MyGlyphPopoverController, _ place: String) {
    let root = controller.view
    root.layoutSubtreeIfNeeded()
    check(root.frame.width > 40 && root.frame.height > 40, "\(place): the popover has a size \(root.frame.size)")
    for label in all(NSTextField.self, in: root) where !label.isHiddenOrHasHiddenAncestor {
        guard let cell = label.cell else { continue }
        let frame = label.convert(label.bounds, to: root)
        check(root.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame), "\(place): “\(label.stringValue)” stays inside \(frame) \(root.bounds)")
        if cell.wraps {
            let needed = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: label.frame.width, height: .greatestFiniteMagnitude)).height
            check(label.frame.height >= needed - 1, "\(place): “\(label.stringValue)” is \(label.frame.height) high for \(needed)")
        } else {
            check(label.frame.width >= cell.cellSize.width - 1, "\(place): “\(label.stringValue)” is \(label.frame.width) wide for \(cell.cellSize.width)")
        }
    }
}

func render(_ controller: MyGlyphPopoverController, appearance: NSAppearance.Name, to url: URL) {
    let root = controller.view
    root.appearance = NSAppearance(named: appearance)
    root.layoutSubtreeIfNeeded()
    let rep = root.bitmapImageRepForCachingDisplay(in: root.bounds)!
    root.appearance!.performAsCurrentDrawingAppearance {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        (appearance == .darkAqua ? NSColor(white: 0.18, alpha: 1) : NSColor(white: 0.96, alpha: 1)).setFill()
        root.bounds.fill()
        NSGraphicsContext.restoreGraphicsState()
        root.cacheDisplay(in: root.bounds, to: rep)
    }
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let language = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "en"
_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
var shown: [(String, MyGlyphPopoverController)] = []
func info(_ string: String) -> MyGlyphPopoverController {
    let controller = MyGlyphPopoverController(character: string)!
    _ = controller.view
    return controller
}

// Block names: English names of Blocks.txt from ICU, keys that spell out the Character Viewer's abbreviations.
check(UnicodeBlocks.name(of: 0x61) == "Basic Latin" && UnicodeBlocks.name(of: 0xE9) == "Latin-1 Supplement", "block names")
check(UnicodeBlocks.name(of: 0x1F600) == "Emoticons" && UnicodeBlocks.name(of: 0x110000) == nil, "block of an emoji, none beyond Unicode")
check(UnicodeBlocks.key("CJK Unified Ideographs Ext. J") == UnicodeBlocks.key("CJK Unified Ideographs Extension J"), "Ext. is Extension")
check(UnicodeBlocks.key("Arabic Math Alphabetic Symbols") == UnicodeBlocks.key("Arabic Mathematical Alphabetic Symbols"), "Math is Mathematical")
check(UnicodeBlocks.key("N'Ko") == "nko", "letters and digits only")
let table = output.appendingPathComponent("blocks.plist")
try! PropertyListSerialization.data(fromPropertyList: ["ja": ["Basic Latin": "基本ラテン文字", "Emoticons": "顔文字"], "en": [:] as [String: String]],
                                    format: .xml, options: 0).write(to: table)
check(UnicodeBlocks.translations(path: table.path, language: "ja")[UnicodeBlocks.key("Basic Latin")] == "基本ラテン文字", "a table of the Character Viewer's format")
check(UnicodeBlocks.translations(path: "/nonexistent", language: "ja").isEmpty, "a missing table")
// Where the Character Viewer has no table, TeX2img's own Japanese names are used.
UnicodeBlocks.tablePath = nil
UnicodeBlocks.tableLanguage = "xx"
if language == "ja" {
    check(UnicodeBlocks.localizedName("Cuneiform") == "楔形文字", "TeX2img's Japanese block names: \(UnicodeBlocks.localizedName("Cuneiform"))")
}
UnicodeBlocks.tablePath = table.path
UnicodeBlocks.tableLanguage = language

// One character: name, code point, block, category and version.
let a = info("a")
check(text("name", in: a.view) == "LATIN SMALL LETTER A" && text("codePoint", in: a.view) == "U+0061", "the name and code point of a")
check(text("block", in: a.view) == (language == "ja" ? "基本ラテン文字" : "Basic Latin"), "the block of a: \(text("block", in: a.view) ?? "-")")
check(text("category", in: a.view) == "Lowercase Letter (Ll)" && text("version", in: a.view) == "Unicode 1.1", "category and version of a")
check(text("codePoint.label", in: a.view) == NSLocalizedString("Code Point:", comment: ""), "the headings are translated")
shown.append(("a", a))
if language == "ja" {
    // A click shows the name of Unicode, and another the translation again.
    let block = view("block", in: a.view) as! NSTextField
    check(block.toolTip == "Basic Latin", "the tool tip names the block as Unicode does")
    let click = block.gestureRecognizers.first!
    _ = a.perform(NSSelectorFromString("toggleBlockName:"), with: click)
    check(text("block", in: a.view) == "Basic Latin", "a click shows the Unicode name")
    let again = view("block", in: a.view) as! NSTextField
    _ = a.perform(NSSelectorFromString("toggleBlockName:"), with: again.gestureRecognizers.first!)
    check(text("block", in: a.view) == "基本ラテン文字", "another click shows the translation")
}
let grin = info("😀")
check(text("codePoint", in: grin.view) == "U+1F600 (U+D83D U+DE00)" && text("name", in: grin.view) == "GRINNING FACE", "a surrogate pair")
shown.append(("emoji", grin))
check(text("name", in: info("✌︎").view)?.hasSuffix("(\(NSLocalizedString("Text Style", comment: "")))") == true, "a text style selector")
check(text("name", in: info("👍🏽").view)?.hasSuffix("(\(NSLocalizedString("Skin Tone IV", comment: "")))") == true, "a skin tone")
check(text("name", in: info("葛\u{E0100}").view)?.hasSuffix("(\(NSLocalizedString("Variant", comment: "")))") == true, "an ideographic variation sequence")
check(view("deprecated", in: info("\u{0149}").view) != nil, "a deprecated character has the badge")
check(text("name", in: info("\u{0378}").view) == NSLocalizedString("Unknown", comment: ""), "an unassigned code point")
check(text("name", in: info("\u{E000}").view) == NSLocalizedString("Unknown", comment: "") && text("block", in: info("\u{E000}").view) != nil,
      "a private-use character has a block")
let tab = info("\t")
check(text("name", in: tab.view)?.isEmpty == false && (view("glyph", in: tab.view)?.accessibilityValue() as? String) == "␉", "a tab shows its picture")
check(text("name", in: info("\u{1F}").view)?.isEmpty == false, "a control character has a name")
// A lone surrogate (the crash risk of docs/audits/CRASH_RISK_AUDIT.md) shows without a crash.
let lone = NSString(characters: [0xD800, 0x61], length: 2) as String
for range in [NSRange(location: 0, length: 1), NSRange(location: 0, length: 2)] {
    let controller = MyGlyphPopoverController(text: lone, ranges: [range])
    check(controller != nil && controller!.view.frame.width > 0, "a lone surrogate in \(range)")
}

// A character of several code points lists them; a triangle opens one.
let accented = info("e\u{0301}")
check(text("name", in: accented.view) == String(format: NSLocalizedString("<a letter consisting of %d characters>", comment: ""), Int32(2)),
      "the number of code points")
check(text("scalar.0.codePoint", in: accented.view) == "U+0065" && text("scalar.1.name", in: accented.view) == "COMBINING ACUTE ACCENT", "the rows")
check(view("scalar.1.detail", in: accented.view) == nil, "the rows are closed at first")
let closedHeight = accented.view.frame.height
(view("scalar.1.disclosure", in: accented.view) as! NSButton).performClick(nil)
check(view("scalar.1.detail", in: accented.view) != nil && text("scalar.1.category", in: accented.view) == "Nonspacing Mark (Mn)",
      "an opened row shows the block and category")
check(accented.view.frame.height > closedHeight, "the popover grows with the opened row")
shown.append(("combining", accented))

// Several characters: counted as TeXShop's status bar counts them, with their code points.
let mixed = "Hi 😀 there\r\nsecond e\u{0301} line" as NSString
check(SelectionCounting.characters(mixed, NSRange(location: 0, length: mixed.length)) == 24, "characters: CR LF and e+accent count once")
check(SelectionCounting.words(mixed, NSRange(location: 0, length: mixed.length)) == 6, "words: an emoji is a word")
check(SelectionCounting.words("\u{0301}" as NSString, NSRange(location: 0, length: 1)) == 0, "a lone mark is no word")
check(SelectionCounting.selectedLines(mixed, [NSRange(location: 0, length: mixed.length)]) == 2, "lines")
check(SelectionCounting.line("a\r\nb" as NSString, at: 2) == 1 && SelectionCounting.line("a\r\nb" as NSString, at: 3) == 2, "CR LF ends one line")
let ranges = [NSRange(location: 0, length: 2), NSRange(location: 13, length: 6)]
let several = MyGlyphPopoverController(text: mixed as String, ranges: ranges)!
_ = several.view
check(several.counts.characters == 8 && several.counts.words == 2 && several.counts.lines == 2, "several ranges: \(several.counts)")
check(text("counts", in: several.view) == String(format: NSLocalizedString("%lu letters, %lu words, %lu lines", comment: ""), 8, 2, 2), "the counts")
let codes = (view("codePoints", in: several.view) as? NSTextView)?.string ?? ""
check(codes == "U+0048  U+0069  U+0073  U+0065  U+0063  U+006F  U+006E  U+0064", "the code points of every range: \(codes)")
shown.append(("several", several))
let long = MyGlyphPopoverController(character: String(repeating: "😀あa", count: 60))!
_ = long.view
check((view("codePointsScroll", in: long.view) as? NSScrollView)?.hasVerticalScroller == true && long.view.frame.height < 400, "a long list scrolls")
check(MyGlyphPopoverController(text: "abc", ranges: [NSRange(location: 1, length: 0)]) == nil, "no character, no popover")
check(MyGlyphPopoverController(text: "abc", ranges: [NSRange(location: 2, length: 5)]) == nil, "a range outside the text")

for (name, controller) in shown {
    checkLayout(controller, name)
    for appearance in [NSAppearance.Name.aqua, .darkAqua] {
        render(controller, appearance: appearance, to: output.appendingPathComponent("\(language)-\(name)-\(appearance == .aqua ? "light" : "dark").png"))
    }
}
try? FileManager.default.removeItem(at: table)
print("Character Info checks passed (\(language))")
