import Foundation

extension NSDate {
    @objc func isNewerThan(_ date: NSDate) -> Bool {
        return (self as Date) >= (date as Date)
    }
}
