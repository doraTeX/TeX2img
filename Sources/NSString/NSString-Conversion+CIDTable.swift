import Foundation

private let cidTableLock = NSLock()
private var cachedCIDToUnicode: [Int: UInt32]?

var cidToUnicode: [Int: UInt32] {
    cidTableLock.lock()
    defer { cidTableLock.unlock() }
    if let cached = cachedCIDToUnicode {
        return cached
    }
    let table = loadCIDToUnicodeTable()
    cachedCIDToUnicode = table
    return table
}

private func loadCIDToUnicodeTable() -> [Int: UInt32] {
    guard let url = Bundle.main.url(forResource: "cidToUnicode", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [String: NSNumber] else {
        return [:]
    }

    var result: [Int: UInt32] = [:]
    result.reserveCapacity(raw.count)
    for (key, value) in raw {
        guard let cid = Int(key) else { continue }
        result[cid] = value.uint32Value
    }
    return result
}
