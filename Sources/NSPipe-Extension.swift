import Foundation

extension Pipe {
    @objc var stringValue: String {
        return String(data: self.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? ""
    }
}
