import Foundation

@objc extension NSColor {
    
    // MARK: - Light Mode Defaults
    static var defaultForegroundColorForLightMode: NSColor {
        return NSColor.black
    }

    static var defaultBackgroundColorForLightMode: NSColor {
        return NSColor.white
    }

    static var defaultCursorColorForLightMode: NSColor {
        return NSColor.black
    }

    static var defaultBraceColorForLightMode: NSColor {
        return NSColor(calibratedRed: 0.02, green: 0.51, blue: 0.13, alpha: 1.0)
    }

    static var defaultCommentColorForLightMode: NSColor {
        return NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }

    static var defaultCommandColorForLightMode: NSColor {
        return NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
    }

    static var defaultInvisibleColorForLightMode: NSColor {
        return NSColor.orange
    }

    static var defaultHighlightedBraceColorForLightMode: NSColor {
        return NSColor.magenta
    }

    static var defaultEnclosedContentBackgroundColorForLightMode: NSColor {
        return NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
    }

    static var defaultFlashingBackgroundColorForLightMode: NSColor {
        return NSColor(calibratedRed: 1.0, green: 0.95, blue: 1.0, alpha: 1.0)
    }

    static var defaultConsoleForegroundColorForLightMode: NSColor {
        return NSColor.black
    }

    static var defaultConsoleBackgroundColorForLightMode: NSColor {
        return NSColor.white
    }

    // MARK: - Dark Mode Defaults
    static var defaultForegroundColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.792, green: 0.843, blue: 0.854, alpha: 1.0)
    }

    static var defaultBackgroundColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.12, alpha: 1.0)
    }

    static var defaultCursorColorForDarkMode: NSColor {
        return NSColor.defaultForegroundColorForDarkMode
    }

    static var defaultBraceColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 1.00, green: 0.980, blue: 0.513, alpha: 1.0)
    }

    static var defaultCommentColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.866, green: 0.603, blue: 0.898, alpha: 1.0)
    }

    static var defaultCommandColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.341, green: 0.709, blue: 0.494, alpha: 1.0)
    }

    static var defaultInvisibleColorForDarkMode: NSColor {
        return NSColor.orange
    }

    static var defaultHighlightedBraceColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 1.00, green: 0.196, blue: 0.341, alpha: 1.0)
    }

    static var defaultEnclosedContentBackgroundColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.250, green: 0.250, blue: 0.215, alpha: 1.0)
    }

    static var defaultFlashingBackgroundColorForDarkMode: NSColor {
        return NSColor(calibratedRed: 0.04, green: 0.13, blue: 0.13, alpha: 1.0)
    }

    static var defaultConsoleForegroundColorForDarkMode: NSColor {
        return NSColor.defaultForegroundColorForDarkMode
    }

    static var defaultConsoleBackgroundColorForDarkMode: NSColor {
        return NSColor.defaultBackgroundColorForDarkMode
    }

    // MARK: - Automatic Choice
    static var defaultForegroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultForegroundColorForDarkMode : NSColor.defaultForegroundColorForLightMode
    }

    static var defaultBackgroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultBackgroundColorForDarkMode : NSColor.defaultBackgroundColorForLightMode
    }

    static var defaultCursorColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultCursorColorForDarkMode : NSColor.defaultCursorColorForLightMode
    }

    static var defaultBraceColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultBraceColorForDarkMode : NSColor.defaultBraceColorForLightMode
    }

    static var defaultCommentColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultCommentColorForDarkMode : NSColor.defaultCommentColorForLightMode
    }

    static var defaultCommandColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultCommandColorForDarkMode : NSColor.defaultCommandColorForLightMode
    }

    static var defaultInvisibleColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultInvisibleColorForDarkMode : NSColor.defaultInvisibleColorForLightMode
    }

    static var defaultHighlightedBraceColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultHighlightedBraceColorForDarkMode : NSColor.defaultHighlightedBraceColorForLightMode
    }

    static var defaultEnclosedContentBackgroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultEnclosedContentBackgroundColorForDarkMode : NSColor.defaultEnclosedContentBackgroundColorForLightMode
    }

    static var defaultFlashingBackgroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultFlashingBackgroundColorForDarkMode : NSColor.defaultFlashingBackgroundColorForLightMode
    }

    static var defaultConsoleForegroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultConsoleForegroundColorForDarkMode : NSColor.defaultConsoleForegroundColorForLightMode
    }

    static var defaultConsoleBackgroundColor: NSColor {
        return NSApp.isDarkMode ? NSColor.defaultConsoleBackgroundColorForDarkMode : NSColor.defaultConsoleBackgroundColorForLightMode
    }

}
