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

    func colorForKey(_ aKey: String) -> NSColor? {
        guard let string = stringForKey(aKey) else { return nil }
        return NSColor(serializedString: string)
    }
}