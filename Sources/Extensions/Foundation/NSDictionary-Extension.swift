import AppKit
import Foundation

@objc extension NSDictionary {
    @objc func floatForKey(_ aKey: String) -> Float {
        return (self[aKey] as? NSNumber)?.floatValue ?? 0
    }

    @objc func integerForKey(_ aKey: String) -> Int {
        return (self[aKey] as? NSNumber)?.intValue ?? 0
    }

    @objc func boolForKey(_ aKey: String) -> Bool {
        return (self[aKey] as? NSNumber)?.boolValue ?? false
    }

    @objc func stringForKey(_ aKey: String) -> String? {
        return self[aKey] as? String
    }

    @objc func arrayForKey(_ aKey: String) -> NSArray? {
        return self[aKey] as? NSArray
    }

    @objc func mutableArrayForKey(_ aKey: String) -> NSMutableArray {
        return NSMutableArray(array: self[aKey] as? [Any] ?? [])
    }

    @objc func dictionaryForKey(_ aKey: String) -> NSDictionary? {
        return self[aKey] as? NSDictionary
    }

    @objc func colorForKey(_ aKey: String) -> NSColor? {
        guard let string = stringForKey(aKey) else { return nil }
        return NSColor(serializedString: string)
    }
}