import AppKit
import Foundation

extension Dictionary where Key == String, Value == Any {
    func floatForKey(_ aKey: String) -> Float {
        (self[aKey] as? NSNumber)?.floatValue ?? 0
    }

    func integerForKey(_ aKey: String) -> Int {
        (self[aKey] as? NSNumber)?.intValue ?? 0
    }

    func boolForKey(_ aKey: String) -> Bool {
        (self[aKey] as? NSNumber)?.boolValue ?? false
    }

    func stringForKey(_ aKey: String) -> String? {
        self[aKey] as? String
    }

    func arrayForKey(_ aKey: String) -> [Any]? {
        self[aKey] as? [Any]
    }

    func dictionaryForKey(_ aKey: String) -> [String: Any]? {
        self[aKey] as? [String: Any]
    }

    /// A finite number greater than zero, or nil: a profile can hold any number, and AppKit takes these as sizes.
    func positiveFiniteNumberForKey(_ aKey: String) -> CGFloat? {
        guard let value = (self[aKey] as? NSNumber)?.doubleValue, value.isFinite, value > 0 else { return nil }
        return CGFloat(value)
    }

    /// The saved frame of a window, or nil when there is none or it is not a frame (not finite, its right or top edge
    /// not either, or no size), or when it is on none of the screens (frames of NSScreen): AppKit raises an exception
    /// for a window placed that far, and one off every screen could not be seen.
    func windowFrame(xKey: String, yKey: String, widthKey: String, heightKey: String, screens: [NSRect]) -> NSRect? {
        guard let x = (self[xKey] as? NSNumber)?.doubleValue, let y = (self[yKey] as? NSNumber)?.doubleValue,
              x.isFinite, y.isFinite, x != 0, y != 0,
              let width = positiveFiniteNumberForKey(widthKey), let height = positiveFiniteNumberForKey(heightKey),
              (x + width).isFinite, (y + height).isFinite else { return nil }
        let frame = NSRect(x: x, y: y, width: width, height: height)
        return screens.contains { $0.intersects(frame) } ? frame : nil
    }

    func colorForKey(_ aKey: String) -> NSColor? {
        guard let string = stringForKey(aKey) else { return nil }
        return NSColor(serializedString: string)
    }
}

/// A tab width the settings accept (1 to 100). A profile can hold any number, and the width is the number of spaces an
/// indent inserts; a width that is not positive is the default, 4.
func validTabWidth(_ width: Int) -> Int {
    width > 0 ? min(width, 100) : 4
}
