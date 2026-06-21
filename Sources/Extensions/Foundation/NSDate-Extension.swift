import Foundation

extension NSDate {
    func isNewerThan(_ date: NSDate) -> Bool {
        return (self as Date) >= (date as Date)
    }
}
