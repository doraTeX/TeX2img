import Foundation

/// User defaults that live in memory only, for the tests: nothing is written to a preferences domain, and nothing has
/// to be removed afterwards. Every accessor that TeX2img's settings code uses is answered from the dictionary.
final class MemoryDefaults: UserDefaults {
    private var values: [String: Any] = [:]

    init() {
        // A suite object is needed for UserDefaults' initializer; it is never read or written.
        super.init(suiteName: "tex2img.memory-defaults.unused")!
    }

    override func object(forKey defaultName: String) -> Any? { values[defaultName] }
    override func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Int, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Bool, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Double, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ value: Float, forKey defaultName: String) { values[defaultName] = value }
    override func set(_ url: URL?, forKey defaultName: String) { values[defaultName] = url }
    override func removeObject(forKey defaultName: String) { values[defaultName] = nil }
    override func string(forKey defaultName: String) -> String? { values[defaultName] as? String }
    override func array(forKey defaultName: String) -> [Any]? { values[defaultName] as? [Any] }
    override func dictionary(forKey defaultName: String) -> [String: Any]? { values[defaultName] as? [String: Any] }
    override func integer(forKey defaultName: String) -> Int { (values[defaultName] as? NSNumber)?.intValue ?? 0 }
    override func bool(forKey defaultName: String) -> Bool { (values[defaultName] as? NSNumber)?.boolValue ?? false }
    override func double(forKey defaultName: String) -> Double { (values[defaultName] as? NSNumber)?.doubleValue ?? 0 }
    override func float(forKey defaultName: String) -> Float { (values[defaultName] as? NSNumber)?.floatValue ?? 0 }
    override func dictionaryRepresentation() -> [String: Any] { values }
    override func synchronize() -> Bool { true }
}
