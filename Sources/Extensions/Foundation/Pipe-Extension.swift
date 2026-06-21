import Foundation

extension Pipe {
    var stringValue: String { String(data: self.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? "" }
}
