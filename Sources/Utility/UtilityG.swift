import AppKit
import Foundation

class UtilityG: NSObject {
    static func runOkPanel(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func runErrorPanel(message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Error", comment: "")
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func runWarningPanel(message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Warning", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static func runConfirmPanel(message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Confirm", comment: "")
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        return alert.runModal() == .alertFirstButtonReturn
    }

    static func isJapaneseLanguage() -> Bool {
        struct Cache {
            static let value: Bool = {
                guard let locale = Locale.preferredLanguages.first else { return false }
                return locale == "ja" || locale == "ja-JP"
            }()
        }
        return Cache.value
    }

    private static func readColor(from profile: Profile,
                                  lightModeKey: String,
                                  darkModeKey: String,
                                  defaultColor: NSColor) -> NSColor {
        let key = NSApp.isDarkMode ? darkModeKey : lightModeKey
        return profile.colorForKey(key) ?? defaultColor
    }

    static func foregroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "foregroundColor",
                  darkModeKey: "foregroundColorForDarkMode",
                  defaultColor: .defaultForegroundColor)
    }

    static func backgroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "backgroundColor",
                  darkModeKey: "backgroundColorForDarkMode",
                  defaultColor: .defaultBackgroundColor)
    }

    static func cursorColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "cursorColor",
                  darkModeKey: "cursorColorForDarkMode",
                  defaultColor: .defaultCursorColor)
    }

    static func braceColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "braceColor",
                  darkModeKey: "braceColorForDarkMode",
                  defaultColor: .defaultBraceColor)
    }

    static func commentColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "commentColor",
                  darkModeKey: "commentColorForDarkMode",
                  defaultColor: .defaultCommentColor)
    }

    static func commandColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "commandColor",
                  darkModeKey: "commandColorForDarkMode",
                  defaultColor: .defaultCommandColor)
    }

    static func invisibleColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "invisibleColor",
                  darkModeKey: "invisibleColorForDarkMode",
                  defaultColor: .defaultInvisibleColor)
    }

    static func highlightedBraceColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "highlightedBraceColor",
                  darkModeKey: "highlightedBraceColorForDarkMode",
                  defaultColor: .defaultHighlightedBraceColor)
    }

    static func enclosedContentBackgroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "enclosedContentBackgroundColor",
                  darkModeKey: "enclosedContentBackgroundColorForDarkMode",
                  defaultColor: .defaultEnclosedContentBackgroundColor)
    }

    static func flashingBackgroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "flashingBackgroundColor",
                  darkModeKey: "flashingBackgroundColorForDarkMode",
                  defaultColor: .defaultFlashingBackgroundColor)
    }

    static func consoleForegroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "consoleForegroundColor",
                  darkModeKey: "consoleForegroundColorForDarkMode",
                  defaultColor: .defaultConsoleForegroundColor)
    }

    static func consoleBackgroundColor(inProfile profile: Profile) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "consoleBackgroundColor",
                  darkModeKey: "consoleBackgroundColorForDarkMode",
                  defaultColor: .defaultConsoleBackgroundColor)
    }
}