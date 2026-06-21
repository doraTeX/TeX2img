import Foundation

@objc extension NSArray {
    @objc func indexesOfTrueValue() -> IndexSet {
        indexesOfObjects { obj, _, _ in
            (obj as? NSNumber)?.boolValue == true
        }
    }

    @objc func mapUsingBlock(_ block: @escaping (Any) -> Any) -> NSArray {
        var result = [Any]()
        result.reserveCapacity(count)
        for item in self {
            result.append(block(item))
        }
        return result as NSArray
    }
}