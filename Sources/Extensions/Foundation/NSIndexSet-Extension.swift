import Cocoa

extension NSIndexSet {
    var arrayOfIndexesPlusOne: [Int] { self.map { $0+1 } }
}



