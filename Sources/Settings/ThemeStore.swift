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
    /// A copy of a bundled theme that is damaged is moved to the backups and put back from the bundled one, without a
    /// message (TeXShop's repair of ~/Library/TeXShop). This is done at launch only: while TeX2img runs, a damaged theme
    /// is read from the bundled copy (ThemeLibrary), since another application may still be saving the file.
    func installBundledThemes(from bundled: URL?) {
        guard let bundled else { return }
        let fileManager = FileManager.default
        let isNew = !fileManager.fileExists(atPath: directory.path)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let names = (try? fileManager.contentsOfDirectory(atPath: bundled.path)) ?? []
        for name in names where name.hasSuffix(".plist") {
            let title = (name as NSString).deletingPathExtension
            guard let destination = url(forTitle: title) else { continue }
            if !isNew && isDamaged(title: title) {
                repair(title: title, at: destination, from: bundled.appendingPathComponent(name))
            } else if (isNew || title == Self.defaultLightTitle || title == Self.defaultDarkTitle)
                        && !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: bundled.appendingPathComponent(name), to: destination)
            }
        }
    }

    /// Puts back a damaged copy. The bundled theme is first copied beside it under a hidden name; then the damaged
    /// file goes to the backups, and the copy takes its place. If a step fails, the damaged file stays (or is put
    /// back), so that the next launch tries again: a theme the user deleted is not brought back, and one that a
    /// repair left half done is not lost.
    private func repair(title: String, at destination: URL, from source: URL) {
        let fileManager = FileManager.default
        let fresh = directory.appendingPathComponent(".\(title).repair-\(UUID().uuidString).plist")
        guard (try? fileManager.copyItem(at: source, to: fresh)) != nil else { return }
        guard let backup = moveToBackups(title: title) else {
            try? fileManager.removeItem(at: fresh)
            return
        }
        if (try? fileManager.moveItem(at: fresh, to: destination)) == nil {
            try? fileManager.removeItem(at: fresh)
            try? fileManager.moveItem(at: backup, to: destination)
        }
    }

    /// Where damaged theme files are kept: ~/Library/Application Support/TeX2img/Backups/Themes.
    var backupDirectory: URL {
        directory.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent("Themes", isDirectory: true)
    }

    /// Whether the file of a theme is there but holds no colors: a folder, unreadable, or not a property list of a
    /// dictionary. A symbolic link and a name that could leave the folder are not checked (they are not used).
    func isDamaged(title: String) -> Bool {
        guard let url = url(forTitle: title) else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return false }
        return isDirectory.boolValue || read(title: title) == nil
    }

    /// Moves the file of a theme to the backups, under a name that no earlier backup has, and returns where it went.
    func moveToBackups(title: String) -> URL? {
        guard let url = url(forTitle: title) else { return nil }
        let fileManager = FileManager.default
        guard (try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)) != nil else { return nil }
        var backup = backupDirectory.appendingPathComponent(title).appendingPathExtension("plist")
        var number = 2
        while fileManager.fileExists(atPath: backup.path) || (try? backup.checkResourceIsReachable()) == true {
            backup = backupDirectory.appendingPathComponent("\(title) \(number)").appendingPathExtension("plist")
            number += 1
        }
        return (try? fileManager.moveItem(at: url, to: backup)) != nil ? backup : nil
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
        // TeXShop 6.00 (1cc26b7d, 35dc9325, 09987057): every color drawn as text and the console text are readable on the
        // background of their themes (contrast 4.5 or more), and most matching braces; the text found by SyncTeX in Dracula
        // and PreTeXt-Dark is readable on its color, and the background of copied images is white. TeX2img draws the text,
        // comment, command, brace, cursor and console colors of these; the others keep the copies the same as the bundled
        // themes. TeX2img Lite, by the same rule: its comments and matching braces (the colors of LiteTheme and GLG-Lite).
        .init(update: 2, theme: "DarkTheme", key: "ImageBackground", from: [0.0, 0.0, 0.0], to: [1.0, 1.0, 1.0]),
        .init(update: 2, theme: "DarkTheme", key: "SyntaxComment", from: [0.4214648995014463, 0.4841349735731593, 0.4887142229806348], to: [0.596078, 0.764706, 0.47451]),
        .init(update: 2, theme: "DarkTheme", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.615686, 0.615686, 0.615686]),
        .init(update: 2, theme: "DarkTheme", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [1.0, 0.423529, 0.541176]),
        .init(update: 2, theme: "DarkTheme", key: "XMLValue", from: [0.6, 0.6, 0.2], to: [0.635294, 0.635294, 0.211765]),
        .init(update: 2, theme: "DarkTheme", key: "explFunction", from: [0.5738074183, 0.5655357838, 0.0], to: [0.647059, 0.635294, 0.0]),
        .init(update: 2, theme: "DarkTheme", key: "explVariable", from: [0.3612271356295268, 0.5538832545280457, 0.1470971305796211], to: [0.443137, 0.682353, 0.180392]),
        .init(update: 2, theme: "DarkTheme", key: "explmsg", from: [0.2445922347363184, 0.5628632708533178, 0.5655312538146973], to: [0.294118, 0.67451, 0.678431]),
        .init(update: 2, theme: "DarkTheme", key: "explmykey", from: [0.5337947981286083, 0.2416767935226142, 0.9631578326225281], to: [0.709804, 0.529412, 0.976471]),
        .init(update: 2, theme: "DarkTheme", key: "explmykeyArgument", from: [0.7865745425224304, 0.3276950635431077, 0.3814485680324715], to: [0.85098, 0.529412, 0.564706]),
        .init(update: 2, theme: "Dracula", key: "EditorReverseSync", from: [0.478431, 0.14902, 0.2], to: [0.439216, 0.137255, 0.184314]),
        .init(update: 2, theme: "Dracula", key: "ImageBackground", from: [0.0, 0.0, 0.0], to: [1.0, 1.0, 1.0]),
        .init(update: 2, theme: "Dracula", key: "SyntaxComment", from: [0.3119781017303467, 0.3640799522399902, 0.5760171413421631], to: [0.639216, 0.682353, 0.858824]),
        .init(update: 2, theme: "Dracula", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.533333, 0.533333, 0.533333]),
        .init(update: 2, theme: "Dracula", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [1.0, 0.211765, 0.368627]),
        .init(update: 2, theme: "GLG-Lite", key: "EditorHighlightBraces", from: [1.0, 0.0, 1.0], to: [0.752941, 0.0, 0.752941]),
        .init(update: 2, theme: "GLG-Lite", key: "SyntaxCommand", from: [0.1294117718935013, 0.4627451002597809, 0.7803921699523926], to: [0.121569, 0.439216, 0.741176]),
        .init(update: 2, theme: "GLG-Lite", key: "SyntaxIndex", from: [0.541176, 0.427451, 0.0], to: [0.533333, 0.419608, 0.0]),
        .init(update: 2, theme: "GLG-Lite", key: "SyntaxMarker", from: [0.8627451062202454, 0.196078434586525, 0.1843137294054031], to: [0.835294, 0.152941, 0.141176]),
        .init(update: 2, theme: "GLG-Lite", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.431373, 0.431373, 0.431373]),
        .init(update: 2, theme: "GLG-Lite", key: "XMLParameter", from: [0.0, 0.541176, 0.0], to: [0.0, 0.505882, 0.0]),
        .init(update: 2, theme: "GLG-Lite", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [0.870588, 0.0, 0.172549]),
        .init(update: 2, theme: "GLG-Lite", key: "XMLValue", from: [0.478431, 0.478431, 0.121569], to: [0.447059, 0.447059, 0.113725]),
        .init(update: 2, theme: "GLG-Lite", key: "explFunction", from: [0.4235, 0.4431, 0.7686], to: [0.376471, 0.396078, 0.74902]),
        .init(update: 2, theme: "GLG-Lite", key: "explIntenseFunction", from: [0.8275, 0.2118, 0.5098], to: [0.792157, 0.172549, 0.47451]),
        .init(update: 2, theme: "GLG-Lite", key: "explVariable", from: [0.5216, 0.6, 0.0], to: [0.4, 0.462745, 0.0]),
        .init(update: 2, theme: "GLG-Lite", key: "explmsg", from: [0.1647, 0.6314, 0.5961], to: [0.12549, 0.478431, 0.454902]),
        .init(update: 2, theme: "GLG-Lite", key: "explmykey", from: [0.7961, 0.2941, 0.0863], to: [0.752941, 0.278431, 0.082353]),
        .init(update: 2, theme: "GLG-Lite", key: "explmykeyArgument", from: [0.7098, 0.5373, 0.0], to: [0.545098, 0.411765, 0.0]),
        .init(update: 2, theme: "LiteTheme", key: "ImageBackground", from: [0.0, 0.0, 0.0], to: [1.0, 1.0, 1.0]),
        .init(update: 2, theme: "LiteTheme", key: "SyntaxComment", from: [1.0, 0.0, 0.0], to: [0.921569, 0.0, 0.0]),
        .init(update: 2, theme: "LiteTheme", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.458824, 0.458824, 0.458824]),
        .init(update: 2, theme: "LiteTheme", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [0.913725, 0.0, 0.184314]),
        .init(update: 2, theme: "LiteTheme", key: "explVariable", from: [0.3084011078, 0.5618229508, 0.0], to: [0.282353, 0.513725, 0.0]),
        .init(update: 2, theme: "LiteTheme", key: "explmsg", from: [0.0, 0.5690457821, 0.5746168494], to: [0.0, 0.509804, 0.513725]),
        .init(update: 2, theme: "LiteTheme", key: "explmykeyArgument", from: [0.8478753566741943, 0.2924012940011032, 0.36077542561165], to: [0.835294, 0.231373, 0.305882]),
        .init(update: 2, theme: "Manteuffel", key: "EditorHighlightBraces", from: [1.0, 0.0, 1.0], to: [0.752941, 0.0, 0.752941]),
        .init(update: 2, theme: "Manteuffel", key: "EditorInsertionPoint", from: [0.08235294371843338, 0.7098039388656616, 0.9137254953384399], to: [0.054902, 0.466667, 0.603922]),
        .init(update: 2, theme: "Manteuffel", key: "FootnoteColor", from: [0.1077135801315308, 0.6468018293380737, 0.8915331959724426], to: [0.07451, 0.466667, 0.639216]),
        .init(update: 2, theme: "Manteuffel", key: "SyntaxCommand", from: [0.043137, 0.52549, 0.701961], to: [0.039216, 0.466667, 0.623529]),
        .init(update: 2, theme: "Manteuffel", key: "SyntaxComment", from: [0.7529411911964417, 0.7411764860153198, 0.729411780834198], to: [0.243137, 0.490196, 0.243137]),
        .init(update: 2, theme: "Manteuffel", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.435294, 0.435294, 0.435294]),
        .init(update: 2, theme: "Manteuffel", key: "XMLParameter", from: [0.0, 0.541176, 0.0], to: [0.0, 0.509804, 0.0]),
        .init(update: 2, theme: "Manteuffel", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [0.878431, 0.0, 0.176471]),
        .init(update: 2, theme: "Manteuffel", key: "XMLValue", from: [0.478431, 0.478431, 0.121569], to: [0.45098, 0.45098, 0.113725]),
        .init(update: 2, theme: "Manteuffel", key: "explFunction", from: [0.2471, 0.4549, 0.7216], to: [0.239216, 0.443137, 0.701961]),
        .init(update: 2, theme: "Manteuffel", key: "explIntenseFunction", from: [0.6039, 0.3569, 0.7098], to: [0.588235, 0.329412, 0.698039]),
        .init(update: 2, theme: "Manteuffel", key: "explIntenseVariable", from: [0.5412, 0.5412, 0.5412], to: [0.435294, 0.435294, 0.435294]),
        .init(update: 2, theme: "Manteuffel", key: "explVariable", from: [0.3608, 0.6039, 0.2353], to: [0.290196, 0.486275, 0.188235]),
        .init(update: 2, theme: "Manteuffel", key: "explmsg", from: [0.1647, 0.6157, 0.5608], to: [0.129412, 0.486275, 0.443137]),
        .init(update: 2, theme: "Manteuffel", key: "explmykey", from: [0.8157, 0.5176, 0.1098], to: [0.611765, 0.388235, 0.082353]),
        .init(update: 2, theme: "Manteuffel", key: "explmykeyArgument", from: [0.7608, 0.3216, 0.2902], to: [0.745098, 0.286275, 0.25098]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "EditorReverseSync", from: [0.5807225108, 0.066734083, 0.0], to: [0.486275, 0.054902, 0.0]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "ImageBackground", from: [0.0, 0.0, 0.0], to: [1.0, 1.0, 1.0]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "SyntaxComment", from: [0.4214648995014463, 0.4841349735731593, 0.4887142229806348], to: [0.662745, 0.713725, 0.721569]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.529412, 0.529412, 0.529412]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "XMLTag", from: [1.0, 0.0, 0.3689290583133698], to: [1.0, 0.156863, 0.466667]),
        .init(update: 2, theme: "PreTeXt-Dark", key: "explmykeyArgument", from: [0.9765, 0.149, 0.4471], to: [0.976471, 0.207843, 0.486275]),
        .init(update: 2, theme: "SolarizedDark", key: "FootnoteColor", from: [0.8104339838027954, 0.1117527186870575, 0.1393231600522995], to: [0.917647, 0.392157, 0.415686]),
        .init(update: 2, theme: "SolarizedDark", key: "SyntaxCommand", from: [0.8600000143051147, 0.1959999948740005, 0.1840000003576279], to: [0.894118, 0.403922, 0.396078]),
        .init(update: 2, theme: "SolarizedDark", key: "SyntaxComment", from: [0.5992382592506159, 0.1415595600346804, 0.849357360208095], to: [0.611765, 0.8, 0.239216]),
        .init(update: 2, theme: "SolarizedDark", key: "SyntaxIndex", from: [0.8299999833106995, 0.2099999934434891, 0.5099999904632568], to: [0.870588, 0.4, 0.627451]),
        .init(update: 2, theme: "SolarizedDark", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.560784, 0.560784, 0.560784]),
        .init(update: 2, theme: "SolarizedDark", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [1.0, 0.290196, 0.431373]),
        .init(update: 2, theme: "SolarizedDark", key: "explFunction", from: [0.149, 0.5451, 0.8235], to: [0.2, 0.584314, 0.854902]),
        .init(update: 2, theme: "SolarizedDark", key: "explIntenseFunction", from: [0.4235, 0.4431, 0.7686], to: [0.521569, 0.537255, 0.807843]),
        .init(update: 2, theme: "SolarizedDark", key: "explmykey", from: [0.7961, 0.2941, 0.0863], to: [0.913725, 0.403922, 0.192157]),
        .init(update: 2, theme: "SolarizedLite", key: "EditorHighlightBraces", from: [1.0, 0.0, 1.0], to: [0.752941, 0.0, 0.752941]),
        .init(update: 2, theme: "SolarizedLite", key: "EditorText", from: [0.4000000059604645, 0.4799999892711639, 0.5099999904632568], to: [0.372549, 0.447059, 0.478431]),
        .init(update: 2, theme: "SolarizedLite", key: "LogText", from: [0.4000000059604645, 0.4799999892711639, 0.5099999904632568], to: [0.372549, 0.447059, 0.478431]),
        .init(update: 2, theme: "SolarizedLite", key: "SyntaxCommand", from: [0.8600000143051147, 0.1959999948740005, 0.1840000003576279], to: [0.839216, 0.156863, 0.145098]),
        .init(update: 2, theme: "SolarizedLite", key: "SyntaxComment", from: [0.5799999833106995, 0.6299999952316284, 0.6299999952316284], to: [0.376471, 0.396078, 0.74902]),
        .init(update: 2, theme: "SolarizedLite", key: "SyntaxIndex", from: [0.8299999833106995, 0.2099999934434891, 0.5099999904632568], to: [0.796078, 0.172549, 0.47451]),
        .init(update: 2, theme: "SolarizedLite", key: "SyntaxMarker", from: [0.8299999833106995, 0.2099999934434891, 0.5099999904632568], to: [0.796078, 0.172549, 0.47451]),
        .init(update: 2, theme: "SolarizedLite", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.435294, 0.435294, 0.435294]),
        .init(update: 2, theme: "SolarizedLite", key: "XMLParameter", from: [0.0, 0.541176, 0.0], to: [0.0, 0.509804, 0.0]),
        .init(update: 2, theme: "SolarizedLite", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [0.87451, 0.0, 0.176471]),
        .init(update: 2, theme: "SolarizedLite", key: "XMLValue", from: [0.478431, 0.478431, 0.121569], to: [0.447059, 0.447059, 0.113725]),
        .init(update: 2, theme: "SolarizedLite", key: "explFunction", from: [0.149, 0.5451, 0.8235], to: [0.12549, 0.454902, 0.686275]),
        .init(update: 2, theme: "SolarizedLite", key: "explIntenseFunction", from: [0.4235, 0.4431, 0.7686], to: [0.376471, 0.396078, 0.74902]),
        .init(update: 2, theme: "SolarizedLite", key: "explVariable", from: [0.5216, 0.6, 0.0], to: [0.4, 0.462745, 0.0]),
        .init(update: 2, theme: "SolarizedLite", key: "explmsg", from: [0.1647, 0.6314, 0.5961], to: [0.12549, 0.478431, 0.454902]),
        .init(update: 2, theme: "SolarizedLite", key: "explmykey", from: [0.7961, 0.2941, 0.0863], to: [0.756863, 0.278431, 0.082353]),
        .init(update: 2, theme: "SolarizedLite", key: "explmykeyArgument", from: [0.7098, 0.5373, 0.0], to: [0.545098, 0.411765, 0.0]),
        .init(update: 2, theme: "TransparentTheme", key: "ConsoleText", from: [0.03342935759671994, 0.490464023518719, 1.0], to: [0.0, 0.423529, 0.898039]),
        .init(update: 2, theme: "TransparentTheme", key: "EditorText", from: [0.659283788071066, 0.3899459829154598, 0.519830080548534], to: [0.619608, 0.345098, 0.478431]),
        .init(update: 2, theme: "TransparentTheme", key: "FootnoteColor", from: [0.2264918088912964, 0.5419937968254089, 0.9477165937423706], to: [0.058824, 0.411765, 0.870588]),
        .init(update: 2, theme: "TransparentTheme", key: "ImageBackground", from: [0.0, 0.0, 0.0], to: [1.0, 1.0, 1.0]),
        .init(update: 2, theme: "TransparentTheme", key: "SyntaxCommand", from: [0.2747414999891776, 0.6231743567483239, 0.9596965909004211], to: [0.043137, 0.431373, 0.807843]),
        .init(update: 2, theme: "TransparentTheme", key: "SyntaxComment", from: [0.9175150990486145, 0.4509730964372159, 0.05484317457009981], to: [0.760784, 0.254902, 0.047059]),
        .init(update: 2, theme: "TransparentTheme", key: "XMLComment", from: [0.5, 0.5, 0.5], to: [0.431373, 0.431373, 0.431373]),
        .init(update: 2, theme: "TransparentTheme", key: "XMLParameter", from: [0.0, 0.541176, 0.0], to: [0.0, 0.505882, 0.0]),
        .init(update: 2, theme: "TransparentTheme", key: "XMLTag", from: [1.0, 0.0, 0.2], to: [0.87451, 0.0, 0.176471]),
        .init(update: 2, theme: "TransparentTheme", key: "XMLValue", from: [0.478431, 0.478431, 0.121569], to: [0.447059, 0.447059, 0.113725]),
        .init(update: 2, theme: "TransparentTheme", key: "explIntenseFunction", from: [0.7059, 0.2824, 0.6078], to: [0.690196, 0.27451, 0.592157]),
        .init(update: 2, theme: "TransparentTheme", key: "explIntenseVariable", from: [0.4588, 0.4588, 0.4588], to: [0.431373, 0.431373, 0.431373]),
        .init(update: 2, theme: "TransparentTheme", key: "explVariable", from: [0.1804, 0.5451, 0.3412], to: [0.160784, 0.490196, 0.305882]),
        .init(update: 2, theme: "TransparentTheme", key: "explmsg", from: [0.0, 0.5137, 0.5608], to: [0.0, 0.482353, 0.52549]),
        .init(update: 2, theme: "TeX2img Lite", key: "SyntaxComment", from: [1.0, 0.0, 0.0], to: [0.921569, 0.0, 0.0]),
        .init(update: 2, theme: "TeX2img Lite", key: "EditorHighlightBraces", from: [1.0, 0.0, 1.0], to: [0.752941, 0.0, 0.752941]),
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
    private let bundledDirectory: URL?
    private var cache: [String: ThemeColors] = [:]

    init(store: ThemeStore, bundledDirectory: URL? = ThemeStore.bundledDirectory) {
        self.store = store
        self.bundledDirectory = bundledDirectory
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
        // A damaged copy of a bundled theme is read from the bundled one until the next launch repairs it.
        let bundled = store.isDamaged(title: title) ? bundledDirectory.flatMap { ThemeStore(directory: $0).read(title: title) } : nil
        guard let colors = store.read(title: title) ?? bundled else { return nil }
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
