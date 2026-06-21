import Foundation

enum ExitStatus: Int {
    case succeeded = 0
    case failed = 1
    case aborted = 2
}

enum HighlightPattern: Int {
    case flash = 0
    case solid = 1
    case noHighlight = 2
}

let FLASH = HighlightPattern.flash.rawValue
let SOLID = HighlightPattern.solid.rawValue
let NOHIGHLIGHT = HighlightPattern.noHighlight.rawValue

protocol DnDDelegate: AnyObject {
    func textViewDroppedFile(_ file: Any)
}