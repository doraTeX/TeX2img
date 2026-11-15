import AppKit

/// A color theme in TeXShop's format: a property list whose values are [red, green, blue, alpha] arrays.
typealias ThemeColors = [String: Any]

/// The theme colors TeX2img uses, with the TeXShop key that stores each of them.
enum ThemeRole: CaseIterable {
    case text, background, cursor, flash
    case comment, command, marker
    case invisible, highlightedBrace, enclosedContent
    case consoleText, consoleBackground
    /// Fullwidth letters, digits and symbols and the minus sign, easily mistaken for ASCII (TeXShop 5.60).
    case fullwidthSymbol, fullwidthBackground

    /// Only the flashing background is drawn with its opacity; the other colors are drawn opaque,
    /// and their wells offer no opacity (TeXShop's useOpaqueColorWells).
    var usesOpacity: Bool { self == .flash || self == .fullwidthBackground }

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
        case .fullwidthSymbol: return "EditorHighlightZenkakuSymbol"
        case .fullwidthBackground: return "EditorHighlightZenkakuSymbolBackground"
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
        // Coordinated with the update of the bundled theme colors at the launch of another TeX2img.
        var coordinationError: NSError?
        var writeError: Error?
        var written = false
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { url in
            do {
                try data.write(to: url, options: .atomic)
                written = true
            } catch {
                writeError = error
            }
        }
        if !written { throw writeError ?? coordinationError ?? CocoaError(.fileWriteUnknown) }
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

/// A color of a bundled theme that a later version changed (TeXShop's TSBundledThemeColorChanges).
struct BundledThemeColorChange {
    let update: Int
    let theme: String
    let key: String
    let from: [Double]
    let to: [Double]
}

extension ThemeStore {
    static let bundledColorsUpdateKey = "BundledThemeColorsUpdate"

    /// The themes in the theme folder are copies made when the folder was created. Each change belongs to an update;
    /// the last update done is kept in the user defaults.
    static let bundledColorChanges: [BundledThemeColorChange] = [
        // TeXShop 6.00: the content of braces, the active line and the text found by SyncTeX are painted behind the text,
        // which must stay readable on them; brackets, markers, index entries, XML and the commands of Manteuffel are made
        // readable on the background of their themes. TeX2img draws the content of braces, the curly braces and the commands.
        .init(update: 1, theme: "DarkTheme", key: "EditorHighlightContent", from: [0.4756349325, 0.4756467342, 0.4756404161], to: [0.270588, 0.25098, 0.176471]),
        .init(update: 1, theme: "DarkTheme", key: "EntryColor", from: [0.6386525630950928, 0.1230164617300034, 0.1503929197788239], to: [0.258824, 0.258824, 0.258824]),
        .init(update: 1, theme: "DarkTheme", key: "XMLSpecial", from: [0.0, 0.3, 1.0], to: [0.431373, 0.607843, 1.0]),
        .init(update: 1, theme: "Dracula", key: "EditorHighlightContent", from: [0.4756349325, 0.4756467342, 0.4756404161], to: [0.25098, 0.243137, 0.172549]),
        .init(update: 1, theme: "Dracula", key: "EditorReverseSync", from: [0.9872317910194397, 0.2329826056957245, 0.2662559449672699], to: [0.478431, 0.14902, 0.2]),
        .init(update: 1, theme: "Dracula", key: "EntryColor", from: [1.0, 0.0, 0.0630970448255539], to: [0.180392, 0.188235, 0.243137]),
        .init(update: 1, theme: "Dracula", key: "SyntaxMarkerCurly", from: [0.0, 0.0, 0.0], to: [0.9725490196078431, 0.9725490196078431, 0.9490196078431372]),
        .init(update: 1, theme: "Dracula", key: "SyntaxMarkerParen", from: [0.0, 0.0, 0.0], to: [0.9725490196078431, 0.9725490196078431, 0.9490196078431372]),
        .init(update: 1, theme: "Dracula", key: "SyntaxMarkerSquare", from: [0.0, 0.0, 0.0], to: [0.9725490196078431, 0.9725490196078431, 0.9490196078431372]),
        .init(update: 1, theme: "Dracula", key: "XMLSpecial", from: [0.0, 0.3, 1.0], to: [0.431373, 0.607843, 1.0]),
        .init(update: 1, theme: "GLG-Lite", key: "EditorReverseSync", from: [0.2000000029802322, 0.6000000238418579, 0.9900000095367432], to: [0.74902, 0.866667, 0.988235]),
        .init(update: 1, theme: "GLG-Lite", key: "SyntaxIndex", from: [1.0, 1.0, 0.0], to: [0.541176, 0.427451, 0.0]),
        .init(update: 1, theme: "GLG-Lite", key: "XMLParameter", from: [0.0, 1.0, 0.0], to: [0.0, 0.541176, 0.0]),
        .init(update: 1, theme: "GLG-Lite", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.478431, 0.478431, 0.121569]),
        .init(update: 1, theme: "LiteTheme", key: "EditorHighlightContent", from: [0.8946298956871033, 0.241200892533709, 0.2138740761137153], to: [1.0, 0.956863, 0.768627]),
        .init(update: 1, theme: "LiteTheme", key: "SyntaxIndex", from: [1.0, 0.9932006001472473, 0.0], to: [0.541176, 0.427451, 0.0]),
        .init(update: 1, theme: "LiteTheme", key: "XMLParameter", from: [0.0, 1.0, 0.0], to: [0.0, 0.541176, 0.0]),
        .init(update: 1, theme: "LiteTheme", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.478431, 0.478431, 0.121569]),
        .init(update: 1, theme: "Manteuffel", key: "SyntaxCommand", from: [0.08235294371843338, 0.7098039388656616, 0.9137254953384399], to: [0.043137, 0.52549, 0.701961]),
        .init(update: 1, theme: "Manteuffel", key: "SyntaxIndex", from: [1.0, 1.0, 0.0], to: [0.541176, 0.427451, 0.0]),
        .init(update: 1, theme: "Manteuffel", key: "XMLParameter", from: [0.0, 1.0, 0.0], to: [0.0, 0.541176, 0.0]),
        .init(update: 1, theme: "Manteuffel", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.478431, 0.478431, 0.121569]),
        .init(update: 1, theme: "PreTeXt-Dark", key: "EditorHighlightContent", from: [0.4756349325, 0.4756467342, 0.4756404161], to: [0.239216, 0.227451, 0.156863]),
        .init(update: 1, theme: "PreTeXt-Dark", key: "EntryColor", from: [1.0, 0.0, 0.0], to: [0.188235, 0.192157, 0.164706]),
        .init(update: 1, theme: "PreTeXt-Dark", key: "XMLSpecial", from: [0.0, 0.3, 1.0], to: [0.431373, 0.607843, 1.0]),
        .init(update: 1, theme: "SolarizedDark", key: "EditorHighlightContent", from: [1.0, 1.0, 0.0], to: [0.2, 0.188235, 0.039216]),
        .init(update: 1, theme: "SolarizedDark", key: "EditorReverseSync", from: [1.0, 1.0, 0.0], to: [0.352941, 0.121569, 0.105882]),
        .init(update: 1, theme: "SolarizedDark", key: "EntryColor", from: [1.0, 0.0, 0.07932668179273605], to: [0.027451, 0.211765, 0.258824]),
        .init(update: 1, theme: "SolarizedDark", key: "XMLSpecial", from: [0.0, 0.3, 1.0], to: [0.431373, 0.607843, 1.0]),
        .init(update: 1, theme: "SolarizedLite", key: "SyntaxMarker", from: [0.1650000065565109, 0.6299999952316284, 0.5960000157356262], to: [0.8299999833106995, 0.2099999934434891, 0.5099999904632568]),
        .init(update: 1, theme: "SolarizedLite", key: "XMLParameter", from: [0.0, 1.0, 0.0], to: [0.0, 0.541176, 0.0]),
        .init(update: 1, theme: "SolarizedLite", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.478431, 0.478431, 0.121569]),
        .init(update: 1, theme: "TransparentTheme", key: "EditorHighlightContent", from: [0.9816838723753915, 0.3395324724758731, 0.1522207877986456], to: [1.0, 0.956863, 0.768627]),
        .init(update: 1, theme: "TransparentTheme", key: "SyntaxIndex", from: [1.0, 1.0, 0.0], to: [0.541176, 0.427451, 0.0]),
        .init(update: 1, theme: "TransparentTheme", key: "SyntaxMarker", from: [1.0, 0.9703128892638841, 0.2354147580939638], to: [0.5, 0.4, 0.0]),
        .init(update: 1, theme: "TransparentTheme", key: "XMLParameter", from: [0.0, 1.0, 0.0], to: [0.0, 0.541176, 0.0]),
        .init(update: 1, theme: "TransparentTheme", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.478431, 0.478431, 0.121569]),
    ]

    /// Gives the colors of the updates after the given one to a copy of a bundled theme, where it still has the old color.
    /// The opacity, if any, stays.
    static func applyBundledColorChanges(to colors: inout ThemeColors, theme: String, after update: Int) -> Bool {
        var changed = false
        for change in bundledColorChanges where change.update > update && change.theme == theme {
            guard var color = colors[change.key] as? [Any], color.count >= 3 else { continue }
            let unchanged = (0..<3).allSatisfy { index in
                (color[index] as? NSNumber).map { abs($0.doubleValue - change.from[index]) < 0.0005 } ?? false
            }
            guard unchanged else { continue }
            for index in 0..<3 { color[index] = NSNumber(value: change.to[index]) }
            colors[change.key] = color
            changed = true
        }
        return changed
    }

    /// Updates one theme file; false if it is there but could not be read or written. Another TeX2img may save the theme
    /// at the same time: the file is coordinated with the theme saves, and replaced only if it still holds what was read;
    /// otherwise it is read again, so that a color saved meanwhile is kept.
    private func updateBundledThemeFile(_ url: URL, theme: String, after update: Int) -> Bool {
        var done = false
        var coordinationError: NSError?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forMerging, error: &coordinationError) { url in
            for _ in 0..<5 {
                guard let data = try? Data(contentsOf: url),
                      var colors = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? ThemeColors else { return }
                guard Self.applyBundledColorChanges(to: &colors, theme: theme, after: update) else { done = true; return }
                guard let updated = try? PropertyListSerialization.data(fromPropertyList: colors, format: .xml, options: 0) else { return }
                guard (try? Data(contentsOf: url)) == data else { continue }
                done = (try? updated.write(to: url, options: .atomic)) != nil
                return
            }
        }
        return done
    }

    /// Returns the last update done: every update after the given one, or the given one if a theme that is there could
    /// not be read or written, so that the update is tried again at the next launch. A theme that is not there, or is
    /// reached through a symbolic link, is left alone; so are renamed copies and the user's own themes.
    func updateBundledThemeColors(after update: Int) -> Int {
        let last = Self.bundledColorChanges.map(\.update).max() ?? update
        guard last > update else { return update }
        var themes: [String] = []
        for change in Self.bundledColorChanges where change.update > update && !themes.contains(change.theme) {
            themes.append(change.theme)
        }
        var written = true
        for theme in themes {
            guard let url = url(forTitle: theme), FileManager.default.fileExists(atPath: url.path) else { continue }
            if !updateBundledThemeFile(url, theme: theme, after: update) { written = false }
        }
        return written ? last : update
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
        // A theme without the fullwidth colors shows those characters like other text.
        if role == .fullwidthSymbol, color(theme, key: role.key) == nil { return color(.text, in: theme, dark: dark) }
        if role == .fullwidthBackground, color(theme, key: role.key) == nil { return color(.background, in: theme, dark: dark) }
        let color = color(theme, key: role.key) ?? defaultColor(role, dark: dark)
        return role.usesOpacity ? color : color.withAlphaComponent(1)
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
        case (.fullwidthSymbol, _): return defaultColor(.text, dark: dark)
        case (.fullwidthBackground, _): return defaultColor(.background, dark: dark)
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

    /// Whether two themes agree in every color TeX2img draws. Keys that only TeXShop uses,
    /// such as the expl3 colors, are ignored.
    static func sameUsedColors(_ a: ThemeColors, _ b: ThemeColors) -> Bool {
        ThemeRole.allCases.allSatisfy { components(a, key: $0.key) == components(b, key: $0.key) }
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

    /// Installs the bundled themes, and once gives earlier copies of them the colors of later versions.
    func prepare(defaults: UserDefaults = .standard) {
        store.installBundledThemes(from: ThemeStore.bundledDirectory)
        let update = defaults.integer(forKey: ThemeStore.bundledColorsUpdateKey)
        let done = store.updateBundledThemeColors(after: update)
        if done != update { defaults.set(done, forKey: ThemeStore.bundledColorsUpdateKey) }
        invalidate()
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

    /// Attributes for fullwidth letters, digits and symbols, or nil when the theme does not color them.
    /// A transparent background adds none.
    func fullwidthAttributes(lightTitle: String?, darkTitle: String?, dark: Bool) -> [NSAttributedString.Key: Any]? {
        let title = (dark ? darkTitle : lightTitle) ?? (dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        let theme = colors(title: title) ?? colors(title: dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let text = ThemePalette.color(theme, key: ThemeRole.fullwidthSymbol.key) { attributes[.foregroundColor] = text.withAlphaComponent(1) }
        if let background = ThemePalette.color(theme, key: ThemeRole.fullwidthBackground.key), background.alphaComponent > 0 {
            attributes[.backgroundColor] = background
        }
        return attributes.isEmpty ? nil : attributes
    }

    static func isHighlightedFullwidthCharacter(_ c: unichar) -> Bool {
        (0xFF01...0xFF0B).contains(c) || c == 0xFF0D || (0xFF0F...0xFF5D).contains(c) || c == 0x2212
    }

    /// Falls back to the default theme of the mode when the selected file cannot be read.
    func color(_ role: ThemeRole, lightTitle: String?, darkTitle: String?, dark: Bool) -> NSColor {
        let title = (dark ? darkTitle : lightTitle) ?? (dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        let theme = colors(title: title) ?? colors(title: dark ? ThemeStore.defaultDarkTitle : ThemeStore.defaultLightTitle)
        return ThemePalette.color(role, in: theme, dark: dark)
    }
}
