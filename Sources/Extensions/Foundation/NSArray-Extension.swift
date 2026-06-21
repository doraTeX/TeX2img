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