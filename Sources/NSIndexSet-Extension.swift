import Cocoa

extension NSIndexSet {
    @objc var arrayOfIndexesPlusOne: [Int] {
        return self.map { $0+1 }
    }
}



