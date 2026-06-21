import Foundation

extension String {
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }

    var pathExtension: String {
        (self as NSString).pathExtension
    }

    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    var standardizingPath: String {
        (self as NSString).standardizingPath
    }

    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }

    var programPath: String {
        components(separatedBy: " ").first ?? ""
    }

    var programName: String {
        programPath.lastPathComponent
    }

    func appendingPathComponent(_ component: String) -> String {
        (self as NSString).appendingPathComponent(component)
    }

    func appendingPathExtension(_ extension: String) -> String? {
        (self as NSString).appendingPathExtension(`extension`)
    }

    func quotingWithDoubleQuotations() -> String {
        "\"\(self)\""
    }

    func pathStringByAppendingPageNumber(_ page: UInt) -> String {
        if page == 1 { return self }
        let basename = lastPathComponent.deletingPathExtension
        let ext = pathExtension
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        return deletingLastPathComponent.appendingPathComponent("\(basename)-\(page)\(suffix)")
    }

    func replacingPathExtension(_ extension: String) -> String {
        deletingLastPathComponent.appendingPathExtension(`extension`) ?? self
    }

    func replacingYenWithBackslash() -> String {
        replacingOccurrences(of: "\u{00A5}", with: "\\")
    }

    func deletingLastReturnCharacters() -> String {
        (self as NSString).stringByDeletingLastReturnCharacters()
    }
}