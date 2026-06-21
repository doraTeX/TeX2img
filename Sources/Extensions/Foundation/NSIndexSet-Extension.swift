import Cocoa

extension NSIndexSet {
    @objc var arrayOfIndexesPlusOne: [Int] { self.map { $0+1 } }
}



