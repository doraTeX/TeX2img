import Foundation

extension BidirectionalCollection {
    subscript(safe offset: Int) -> Element? {
        guard offset >= 0, offset < count else { return nil }
        return self[index(startIndex, offsetBy: offset)]
    }
}
