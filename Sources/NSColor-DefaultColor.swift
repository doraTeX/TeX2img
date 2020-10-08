import Foundation

@objc extension NSColor {
    
    // MARK: - Light Mode Defaults
    static var defaultForegroundColorForLightMode: NSColor { NSColor.black }
    static var defaultBackgroundColorForLightMode: NSColor { NSColor.white }
    static var defaultCursorColorForLightMode: NSColor { NSColor.black }
    static var defaultBraceColorForLightMode: NSColor { NSColor(calibratedRed: 0.02, green: 0.51, blue: 0.13, alpha: 1.0) }
    static var defaultCommentColorForLightMode: NSColor { NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) }
    static var defaultCommandColorForLightMode: NSColor { NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0) }
    static var defaultInvisibleColorForLightMode: NSColor { NSColor.orange }
    static var defaultHighlightedBraceColorForLightMode: NSColor { NSColor.magenta }
    static var defaultEnclosedContentBackgroundColorForLightMode: NSColor { NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.5, alpha: 1.0) }
    static var defaultFlashingBackgroundColorForLightMode: NSColor { NSColor(calibratedRed: 1.0, green: 0.95, blue: 1.0, alpha: 1.0) }
    static var defaultConsoleForegroundColorForLightMode: NSColor { NSColor.black }
    static var defaultConsoleBackgroundColorForLightMode: NSColor { NSColor.white }

    // MARK: - Dark Mode Defaults
    static var defaultForegroundColorForDarkMode: NSColor { NSColor(calibratedRed: 0.792, green: 0.843, blue: 0.854, alpha: 1.0) }
    static var defaultBackgroundColorForDarkMode: NSColor { NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.12, alpha: 1.0) }
    static var defaultCursorColorForDarkMode: NSColor { NSColor.defaultForegroundColorForDarkMode }
    static var defaultBraceColorForDarkMode: NSColor { NSColor(calibratedRed: 0.831, green: 0.819, blue: 0.239, alpha: 1.0) }
    static var defaultCommentColorForDarkMode: NSColor { NSColor(calibratedRed: 0.866, green: 0.603, blue: 0.898, alpha: 1.0) }
    static var defaultCommandColorForDarkMode: NSColor { NSColor(calibratedRed: 0.341, green: 0.709, blue: 0.494, alpha: 1.0) }
    static var defaultInvisibleColorForDarkMode: NSColor { NSColor.orange }
    static var defaultHighlightedBraceColorForDarkMode: NSColor { NSColor(calibratedRed: 1.00, green: 0.196, blue: 0.341, alpha: 1.0) }
    static var defaultEnclosedContentBackgroundColorForDarkMode: NSColor { NSColor(calibratedRed: 0.250, green: 0.250, blue: 0.215, alpha: 1.0) }
    static var defaultFlashingBackgroundColorForDarkMode: NSColor { NSColor(calibratedRed: 0.04, green: 0.13, blue: 0.13, alpha: 1.0) }
    static var defaultConsoleForegroundColorForDarkMode: NSColor { NSColor.defaultForegroundColorForDarkMode }
    static var defaultConsoleBackgroundColorForDarkMode: NSColor { NSColor.defaultBackgroundColorForDarkMode }

    // MARK: - Automatic Choice
    static var defaultForegroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultForegroundColorForDarkMode : NSColor.defaultForegroundColorForLightMode }
    static var defaultBackgroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultBackgroundColorForDarkMode : NSColor.defaultBackgroundColorForLightMode }
    static var defaultCursorColor: NSColor { NSApp.isDarkMode ? NSColor.defaultCursorColorForDarkMode : NSColor.defaultCursorColorForLightMode }
    static var defaultBraceColor: NSColor { NSApp.isDarkMode ? NSColor.defaultBraceColorForDarkMode : NSColor.defaultBraceColorForLightMode }
    static var defaultCommentColor: NSColor { NSApp.isDarkMode ? NSColor.defaultCommentColorForDarkMode : NSColor.defaultCommentColorForLightMode }
    static var defaultCommandColor: NSColor { NSApp.isDarkMode ? NSColor.defaultCommandColorForDarkMode : NSColor.defaultCommandColorForLightMode }
    static var defaultInvisibleColor: NSColor { NSApp.isDarkMode ? NSColor.defaultInvisibleColorForDarkMode : NSColor.defaultInvisibleColorForLightMode }
    static var defaultHighlightedBraceColor: NSColor { NSApp.isDarkMode ? NSColor.defaultHighlightedBraceColorForDarkMode : NSColor.defaultHighlightedBraceColorForLightMode }
    static var defaultEnclosedContentBackgroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultEnclosedContentBackgroundColorForDarkMode : NSColor.defaultEnclosedContentBackgroundColorForLightMode }
    static var defaultFlashingBackgroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultFlashingBackgroundColorForDarkMode : NSColor.defaultFlashingBackgroundColorForLightMode }
    static var defaultConsoleForegroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultConsoleForegroundColorForDarkMode : NSColor.defaultConsoleForegroundColorForLightMode }
    static var defaultConsoleBackgroundColor: NSColor { NSApp.isDarkMode ? NSColor.defaultConsoleBackgroundColorForDarkMode : NSColor.defaultConsoleBackgroundColorForLightMode }

}
