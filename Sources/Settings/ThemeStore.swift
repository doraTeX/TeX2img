import AppKit

/// A color theme in TeXShop's format: a property list whose values are [red, green, blue, alpha] arrays.
typealias ThemeColors = [String: Any]

/// The theme colors TeX2img uses, with the TeXShop key that stores each of them.
enum ThemeRole: CaseIterable {
    case text, background, cursor, flash
    case comment, command, marker
    case invisible, highlightedBrace, enclosedContent
    case consoleText, consoleBackground

    var key: String {
        switch self {
        case .text: return "EditorText"
        case .background: return "EditorBackground"
        case .cursor: return "EditorInsertionPoint"
        case .flash: return "EditorFlash"
        case .comment: return "SyntaxComment"
        case .command: return "SyntaxCommand"
        case .marker: return "SyntaxMarkerCurly"
        case .invisible: return "EditorInvisibleChar"
        case .highlightedBrace: return "EditorHighlightBraces"
        case .enclosedContent: return "EditorHighlightContent"
        case .consoleText: return "ConsoleText"
        case .consoleBackground: return "ConsoleBackground"
        }
    }
}

/// Reads and writes theme files in one directory, as TeXShop's TSThemeFileStore does.
struct ThemeStore {
    static let defaultLightTitle = "TeX2img Lite"
    static let defaultDarkTitle = "TeX2img Dark"
    static let bundledDirectoryName = "Themes"

    let directory: URL

    init(directory: URL) {
        self.directory = directory.standardizedFileURL
    }

    static var userDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("TeX2img", isDirectory: true).appendingPathComponent("Themes", isDirectory: true)
    }

    static var texShopDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/TeXShop/Themes", isDirectory: true)
    }

    static var bundledDirectory: URL? {
        Bundle.main.url(forResource: bundledDirectoryName, withExtension: nil)
    }

    /// The file for a theme title, or nil when the title could leave the directory.
    func url(forTitle title: String) -> URL? {
        guard !title.isEmpty, !title.hasPrefix("."),
              title.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\:")) == nil,
              title.rangeOfCharacter(from: .controlCharacters) == nil else { return nil }
        let url = directory.appendingPathComponent(title).appendingPathExtension("plist")
        // An existing symbolic link must not redirect editing or copying outside the directory.
        if let type = try? FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType,
           type == .typeSymbolicLink { return nil }
        guard url.deletingLastPathComponent().resolvingSymlinksInPath() == directory.resolvingSymlinksInPath() else { return nil }
        return url
    }

    func titles() -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.filter { $0.hasSuffix(".plist") && !$0.hasPrefix(".") }
            .map { ($0 as NSString).deletingPathExtension }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func read(title: String) -> ThemeColors? {
        guard let url = url(forTitle: title), let data = try? Data(contentsOf: url) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? ThemeColors
    }

    func write(_ colors: ThemeColors, title: String) throws {
        guard let url = url(forTitle: title) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var copy = colors
        copy["Title"] = title
        let data = try PropertyListSerialization.data(fromPropertyList: copy, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    func contains(title: String) -> Bool {
        guard let url = url(forTitle: title) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Copies the bundled themes into a new directory, and restores TeX2img's two default themes when they are missing.
    func installBundledThemes(from bundled: URL?) {
        guard let bundled else { return }
        let fileManager = FileManager.default
        let isNew = !fileManager.fileExists(atPath: directory.path)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let names = (try? fileManager.contentsOfDirectory(atPath: bundled.path)) ?? []
        for name in names where name.hasSuffix(".plist") {
            let title = (name as NSString).deletingPathExtension
            guard isNew || title == Self.defaultLightTitle || title == Self.defaultDarkTitle,
                  let destination = url(forTitle: title),
                  !fileManager.fileExists(atPath: destination.path) else { continue }
            try? fileManager.copyItem(at: bundled.appendingPathComponent(name), to: destination)
        }
    }
}

/// Color lookup with TeXShop's fallbacks (TSColorSupport).
enum ThemePalette {
    /// Bracket colors added later inherit SyntaxMarker in older themes.
    static func components(_ theme: ThemeColors, key: String) -> [Double]? {
        var value = theme[key]
        if value == nil, ["SyntaxMarkerParen", "SyntaxMarkerCurly", "SyntaxMarkerSquare"].contains(key) {
            value = theme["SyntaxMarker"]
        }
        guard let array = value as? [Any], array.count >= 3 else { return nil }
        var numbers = [Double]()
        for item in array.prefix(4) {
            guard let number = item as? NSNumber, number.doubleValue.isFinite else { return nil }
            numbers.append(min(1, max(0, number.doubleValue)))
        }
        if numbers.count == 3 { numbers.append(1) }
        return numbers
    }

    static func color(_ theme: ThemeColors?, key: String) -> NSColor? {
        guard let theme, let c = components(theme, key: key) else { return nil }
        return NSColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: c[3])
    }

    /// The color of a role in a theme, or the default of that mode when the theme lacks it.
    static func color(_ role: ThemeRole, in theme: ThemeColors?, dark: Bool) -> NSColor {
        color(theme, key: role.key) ?? defaultColor(role, dark: dark)
    }

    static func defaultColor(_ role: ThemeRole, dark: Bool) -> NSColor {
        switch (role, dark) {
        case (.text, false): return .defaultForegroundColorForLightMode
        case (.background, false): return .defaultBackgroundColorForLightMode
        case (.cursor, false): return .defaultCursorColorForLightMode
        case (.flash, false): return .defaultFlashingBackgroundColorForLightMode
        case (.comment, false): return .defaultCommentColorForLightMode
        case (.command, false): return .defaultCommandColorForLightMode
        case (.marker, false): return .defaultBraceColorForLightMode
        case (.invisible, false): return .defaultInvisibleColorForLightMode
        case (.highlightedBrace, false): return .defaultHighlightedBraceColorForLightMode
        case (.enclosedContent, false): return .defaultEnclosedContentBackgroundColorForLightMode
        case (.consoleText, false): return .defaultConsoleForegroundColorForLightMode
        case (.consoleBackground, false): return .defaultConsoleBackgroundColorForLightMode
        case (.text, true): return .defaultForegroundColorForDarkMode
        case (.background, true): return .defaultBackgroundColorForDarkMode
        case (.cursor, true): return .defaultCursorColorForDarkMode
        case (.flash, true): return .defaultFlashingBackgroundColorForDarkMode
        case (.comment, true): return .defaultCommentColorForDarkMode
        case (.command, true): return .defaultCommandColorForDarkMode
        case (.marker, true): return .defaultBraceColorForDarkMode
        case (.invisible, true): return .defaultInvisibleColorForDarkMode
        case (.highlightedBrace, true): return .defaultHighlightedBraceColorForDarkMode
        case (.enclosedContent, true): return .defaultEnclosedContentBackgroundColorForDarkMode
        case (.consoleText, true): return .defaultConsoleForegroundColorForDarkMode
        case (.consoleBackground, true): return .defaultConsoleBackgroundColorForDarkMode
        }
    }

    static func components(of color: NSColor) -> [NSNumber]? {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        return [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent].map { NSNumber(value: Double($0)) }
    }

    static func set(_ color: NSColor, for key: String, in theme: inout ThemeColors) {
        if let value = components(of: color) { theme[key] = value }
    }

    /// Whether two themes show the same colors (titles are ignored).
    static func sameColors(_ a: ThemeColors, _ b: ThemeColors) -> Bool {
        var a = a, b = b
        a["Title"] = nil
        b["Title"] = nil
        return NSDictionary(dictionary: a).isEqual(to: b)
    }
}

/// The selected light and dark themes, read once and refreshed when a theme file is saved.
final class ThemeLibrary {
    static let shared = ThemeLibrary(store: ThemeStore(directory: ThemeStore.userDirectory))

    let store: ThemeStore
    private var cache: [String: ThemeColors] = [:]

    init(store: ThemeStore) {
        self.store = store
    }

    func prepare() {
        store.installBundledThemes(from: ThemeStore.bundledDirectory)
    }

    func colors(title: String) -> ThemeColors? {
        if let cached = cache[title] { return cached }
        guard let colors = store.read(title: title) else { return nil }
        cache[title] = colors
        return colors
    }

    func invalidate(title: String? = nil) {
        if let title { cache[title] = nil } else { cache.removeAll() }
    }

    /// Falls back to the default theme of the mode when the selected file cannot be read.
    func color(_ role: ThemeRole, lightTitle: String?, darkTitle: String?, dark: Bool) -> NSColor {
        let title = (dark ? darkTitle : lightTitle) ?? (dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        let theme = colors(title: title) ?? colors(title: dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        return ThemePalette.color(role, in: theme, dark: dark)
    }
}
