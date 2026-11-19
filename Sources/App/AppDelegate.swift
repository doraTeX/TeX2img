import Cocoa

/// Installed before NSApplicationMain. The main nib calls setFont: from awakeFromNib, which is before
/// applicationWillFinishLaunching, and NSTextView raises if that font is nil.
@main
enum AppMain {
    static func main() {
        NSTextView.installNilFontGuard()
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

extension NSTextView {
    /// setFont: and setFont:range: both raise NSInvalidArgumentException when the font is nil.
    /// Every NSTextView in the process goes through these methods, including AppKit's own calls.
    static func installNilFontGuard() {
        if nilFontGuardInstalled { return }
        nilFontGuardInstalled = true

        let setter = #selector(setter: NSTextView.font)
        if let method = class_getInstanceMethod(self, setter) {
            originalSetFont = unsafeBitCast(method_getImplementation(method), to: FontSetter.self)
            let block: @convention(block) (AnyObject, NSFont?) -> Void = { object, font in
                guard let font, let original = originalSetFont else { return }
                original(object, setter, font)
            }
            install(setter, method: method, block: block)
        }

        let ranged = NSSelectorFromString("setFont:range:")
        if let method = class_getInstanceMethod(self, ranged) {
            originalSetFontRange = unsafeBitCast(method_getImplementation(method), to: RangedFontSetter.self)
            let block: @convention(block) (AnyObject, NSFont?, NSRange) -> Void = { object, font, range in
                guard let font, let original = originalSetFontRange else { return }
                original(object, ranged, font, range)
            }
            install(ranged, method: method, block: block)
        }
    }

    private typealias FontSetter = @convention(c) (AnyObject, Selector, NSFont?) -> Void
    private typealias RangedFontSetter = @convention(c) (AnyObject, Selector, NSFont?, NSRange) -> Void

    private static var originalSetFont: FontSetter?
    private static var originalSetFontRange: RangedFontSetter?
    /// imp_implementationWithBlock copies the block. This keeps the Swift values alive as well.
    private static var nilFontGuardBlocks: [AnyObject] = []
    private static var nilFontGuardInstalled = false

    private static func install(_ selector: Selector, method: Method, block: Any) {
        nilFontGuardBlocks.append(block as AnyObject)
        let imp = imp_implementationWithBlock(block)
        if let types = method_getTypeEncoding(method), class_addMethod(self, selector, imp, types) {
            return
        }
        method_setImplementation(method, imp)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var observer: NSKeyValueObservation?

    @IBOutlet weak var controllerG: ControllerG?

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        controllerG?.startKeyboardShortcuts()
        if #available(macOS 10.14, *) {
            // アウトプットウィンドウだけはライトモード・ダークモードの変更検出を自力でできないので，AppDelegate で変更を検知して ControllerG に対応を依頼する
            observer = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
                self?.controllerG?.refreshOutputTextView(usingProfile: nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        observer?.invalidate()
        observer = nil
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        controllerG?.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: true) ?? false
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        // The Apple Event that opened the files waits for this answer.
        guard let filename = filenames.first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }
        let imported = controllerG?.importSource(fromFilePathOrPDFDocument: filename, skipConfirm: false) ?? false
        sender.reply(toOpenOrPrint: imported ? .success : .failure)
    }
}
