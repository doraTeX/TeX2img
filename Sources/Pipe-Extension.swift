import Foundation

extension Pipe {
    @objc var stringValue: String { String(data: self.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? "" }
}
