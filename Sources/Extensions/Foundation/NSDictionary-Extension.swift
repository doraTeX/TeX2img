import AppKit
import Foundation

extension NSDictionary {
    func floatForKey(_ aKey: String) -> Float {
        return (self[aKey] as? NSNumber)?.floatValue ?? 0
    }

    func integerForKey(_ aKey: String) -> Int {
        return (self[aKey] as? NSNumber)?.intValue ?? 0
    }

    func boolForKey(_ aKey: String) -> Bool {
        return (self[aKey] as? NSNumber)?.boolValue ?? false
    }

    func stringForKey(_ aKey: String) -> String? {
        return self[aKey] as? String
    }

    func arrayForKey(_ aKey: String) -> NSArray? {
        return self[aKey] as? NSArray
    }

    func mutableArrayForKey(_ aKey: String) -> NSMutableArray {
        return NSMutableArray(array: self[aKey] as? [Any] ?? [])
    }

    func dictionaryForKey(_ aKey: String) -> NSDictionary? {
        return self[aKey] as? NSDictionary
    }

    func colorForKey(_ aKey: String) -> NSColor? {
        guard let string = stringForKey(aKey) else { return nil }
        return NSColor(serializedString: string)
    }
}