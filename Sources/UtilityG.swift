import AppKit
import Foundation

@objc(UtilityG)
class UtilityG: NSObject {
    @objc(runOkPanelWithTitle:message:)
    static func runOkPanel(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc(runErrorPanelWithMessage:)
    static func runErrorPanel(message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Error", comment: "")
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc(runWarningPanelWithMessage:)
    static func runWarningPanel(message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Warning", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc(runConfirmPanelWithMessage:)
    static func runConfirmPanel(message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Confirm", comment: "")
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        return alert.runModal() == .alertFirstButtonReturn
    }

    @objc static func isJapaneseLanguage() -> Bool {
        struct Cache {
            static let value: Bool = {
                guard let locale = Locale.preferredLanguages.first else { return false }
                return locale == "ja" || locale == "ja-JP"
            }()
        }
        return Cache.value
    }

    private static func readColor(from profile: NSDictionary,
                                  lightModeKey: String,
                                  darkModeKey: String,
                                  defaultColor: NSColor) -> NSColor {
        let key = NSApp.isDarkMode ? darkModeKey : lightModeKey
        return profile.colorForKey(key) ?? defaultColor
    }

    @objc(foregroundColorInProfile:)
    static func foregroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "foregroundColor",
                  darkModeKey: "foregroundColorForDarkMode",
                  defaultColor: .defaultForegroundColor)
    }

    @objc(backgroundColorInProfile:)
    static func backgroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "backgroundColor",
                  darkModeKey: "backgroundColorForDarkMode",
                  defaultColor: .defaultBackgroundColor)
    }

    @objc(cursorColorInProfile:)
    static func cursorColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "cursorColor",
                  darkModeKey: "cursorColorForDarkMode",
                  defaultColor: .defaultCursorColor)
    }

    @objc(braceColorInProfile:)
    static func braceColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "braceColor",
                  darkModeKey: "braceColorForDarkMode",
                  defaultColor: .defaultBraceColor)
    }

    @objc(commentColorInProfile:)
    static func commentColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "commentColor",
                  darkModeKey: "commentColorForDarkMode",
                  defaultColor: .defaultCommentColor)
    }

    @objc(commandColorInProfile:)
    static func commandColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "commandColor",
                  darkModeKey: "commandColorForDarkMode",
                  defaultColor: .defaultCommandColor)
    }

    @objc(invisibleColorInProfile:)
    static func invisibleColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "invisibleColor",
                  darkModeKey: "invisibleColorForDarkMode",
                  defaultColor: .defaultInvisibleColor)
    }

    @objc(highlightedBraceColorInProfile:)
    static func highlightedBraceColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "highlightedBraceColor",
                  darkModeKey: "highlightedBraceColorForDarkMode",
                  defaultColor: .defaultHighlightedBraceColor)
    }

    @objc(enclosedContentBackgroundColorInProfile:)
    static func enclosedContentBackgroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "enclosedContentBackgroundColor",
                  darkModeKey: "enclosedContentBackgroundColorForDarkMode",
                  defaultColor: .defaultEnclosedContentBackgroundColor)
    }

    @objc(flashingBackgroundColorInProfile:)
    static func flashingBackgroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "flashingBackgroundColor",
                  darkModeKey: "flashingBackgroundColorForDarkMode",
                  defaultColor: .defaultFlashingBackgroundColor)
    }

    @objc(consoleForegroundColorInProfile:)
    static func consoleForegroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "consoleForegroundColor",
                  darkModeKey: "consoleForegroundColorForDarkMode",
                  defaultColor: .defaultConsoleForegroundColor)
    }

    @objc(consoleBackgroundColorInProfile:)
    static func consoleBackgroundColor(inProfile profile: NSDictionary) -> NSColor {
        readColor(from: profile,
                  lightModeKey: "consoleBackgroundColor",
                  darkModeKey: "consoleBackgroundColorForDarkMode",
                  defaultColor: .defaultConsoleBackgroundColor)
    }
}