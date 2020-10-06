import Foundation

extension Data {
    init?(filePath: String) {
        do {
            try self.init(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            return nil
        }
    }
    
    @discardableResult
    func write(toFile path: String) -> Bool {
        do {
            try self.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
}
