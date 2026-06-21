import Foundation

extension Array where Element == Bool {
    func indexesOfTrueValue() -> IndexSet {
        var indexes = IndexSet()
        for (index, flag) in enumerated() where flag {
            indexes.insert(index)
        }
        return indexes
    }

    var trueValueCount: Int {
        count(where: { $0 })
    }
}

extension NSArray {
    func indexesOfTrueValue() -> IndexSet {
        indexesOfObjects { obj, _, _ in
            (obj as? NSNumber)?.boolValue == true
        }
    }

    func mapUsingBlock(_ block: @escaping (Any) -> Any) -> NSArray {
        var result = [Any]()
        result.reserveCapacity(count)
        for item in self {
            result.append(block(item))
        }
        return result as NSArray
    }
}