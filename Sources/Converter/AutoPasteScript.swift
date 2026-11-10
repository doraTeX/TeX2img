import Foundation

/// The AppleScripts that paste generated images into Office and iWork documents. Each line ends with a newline.
enum AutoPasteScript {
    static func word(_ paths: [String]) -> String {
        var lines = [
            "tell application \"Microsoft Word\"",
            "activate",
            "if version < 15 then",
            "tell selection",
            "set myStart to selection start",
            "set myEnd to selection end",
            "end tell",
            "tell active document",
            "set theRange to create range start myStart end myEnd",
        ]
        for posixPath in paths.reversed() {
            lines.append("make new inline picture at theRange with properties {file name:(POSIX file \"\(posixPath)\") as Unicode text, save with document:true}")
        }
        lines += [
            "end tell",
            "else",
            "tell active document",
            "tell application \"System Events\" to (keystroke \"v\" using command down)",
            "end tell",
            "end if",
            "end tell",
        ]
        return script(lines)
    }

    static func powerPoint(_ paths: [String]) -> String {
        var lines = [
            "tell application \"Microsoft PowerPoint\"",
            "activate",
            "if version < 15 then",
            "set thisSlide to slide index of slide of view of active window",
            "tell slide thisSlide of active presentation",
        ]
        for posixPath in paths {
            lines += [
                "set thePicture to make new picture at end with properties {file name:(POSIX file \"\(posixPath)\") as Unicode text, save with document:true}",
                "tell thePicture",
                "scale height factor 1 scale scale from top left with relative to original size",
                "scale width factor 1 scale scale from top left with relative to original size",
                "end tell",
            ]
        }
        lines += [
            "end tell",
            "else",
            "tell active presentation",
            "tell application \"System Events\" to (keystroke \"v\" using command down)",
            "end tell",
            "end if",
            "end tell",
        ]
        return script(lines)
    }

    static func iWork(_ appName: String) -> String {
        script([
            "tell application \"\(appName)\"",
            "activate",
            "tell document",
            "tell application \"System Events\" to (keystroke \"v\" using command down)",
            "end tell",
            "end tell",
        ])
    }

    private static func script(_ lines: [String]) -> String {
        lines.map { $0 + "\n" }.joined()
    }
}
