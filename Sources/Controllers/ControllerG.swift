import AppKit
import Foundation
import Quartz
import UserNotifications

private let enabledLabel = "enabled"
private let disabledLabel = "disabled"
private let autoSavedProfileName = "*AutoSavedProfile*"
private let templateDirectoryName = "Templates"
private let eaKey = "com.loveinequality.TeX2img"
private let targetExtensions = ["eps", "pdf", "svg", "svgz", "jpg", "png", "gif", "tiff", "bmp"]
private let importExtensions = ["eps", "pdf", "svg", "svgz", "jpg", "png", "gif", "tiff", "bmp", "tex"]
private let inputExtensions = ["tex", "pdf", "ps", "eps"]
private enum InputMethod: Int {
    case direct = 0
    case fromFile = 1
}

private enum EncodingTag: Int {
    case none = 0
    case utf8 = 1
    case sjis = 2
    case jis = 3
    case euc = 4
}

class ControllerG: NSObject, OutputController, DnDDelegate {
    @IBOutlet var sourceTextView: TeXTextView!
    var commandCompletionList: String?

    @IBOutlet private var profileController: ProfileController!
    @IBOutlet private var mainWindow: NSWindow!
    @IBOutlet private var outputWindow: NSWindow!
    @IBOutlet private var outputTextView: NSTextView!
    @IBOutlet private var outputFileTextField: NSTextField!
    @IBOutlet private var extensionPopupButton: NSPopUpButton!
    @IBOutlet private var templatePopupButton: NSPopUpButton!

    @IBOutlet private var preambleWindow: NSWindow!
    @IBOutlet private var preambleTextView: TeXTextView!
    @IBOutlet private var convertYenMarkMenuItem: NSMenuItem!
    @IBOutlet private var richTextMenuItem: NSMenuItem!
    @IBOutlet private var outputWindowMenuItem: NSMenuItem!
    @IBOutlet private var preambleWindowMenuItem: NSMenuItem!
    @IBOutlet private var generateMenuItem: NSMenuItem!
    @IBOutlet private var abortMenuItem: NSMenuItem!
    @IBOutlet private var autoCompleteMenuItem: NSMenuItem!
    @IBOutlet private var autoIndentMenuItem: NSMenuItem!

    @IBOutlet private var flashInMovingCheckBox: NSButton!
    @IBOutlet private var highlightContentCheckBox: NSButton!
    @IBOutlet private var beepCheckBox: NSButton!
    @IBOutlet private var flashBackgroundCheckBox: NSButton!
    @IBOutlet private var checkBraceCheckBox: NSButton!
    @IBOutlet private var checkBracketCheckBox: NSButton!
    @IBOutlet private var checkSquareCheckBox: NSButton!
    @IBOutlet private var checkParenCheckBox: NSButton!

    @IBOutlet private var fontTextField: NSTextField!
    @IBOutlet private var tabWidthTextField: NSTextField!
    @IBOutlet private var tabWidthStepper: NSStepper!
    @IBOutlet private var tabIndentCheckBox: NSButton!
    @IBOutlet private var wrapLineCheckBox: NSButton!

    @IBOutlet private var showTabCharacterCheckBox: NSButton!
    @IBOutlet private var showSpaceCharacterCheckBox: NSButton!
    @IBOutlet private var showNewLineCharacterCheckBox: NSButton!
    @IBOutlet private var showFullwidthSpaceCharacterCheckBox: NSButton!

    @IBOutlet private var commandCompletionKeyMatrix: NSMatrix!

    @IBOutlet private var colorPalleteWindow: NSWindow!
    @IBOutlet private var colorPalleteWindowMenuItem: NSMenuItem!
    @IBOutlet private var colorPalleteColorWell: NSColorWell!
    @IBOutlet private var colorStyleMatrix: NSMatrix!
    @IBOutlet private var colorTextField: NSTextField!

    @IBOutlet private var directInputButton: NSButton!
    @IBOutlet private var inputSourceFileButton: NSButton!
    @IBOutlet private var inputSourceFileTextField: NSTextField!
    @IBOutlet private var browseSourceFileButton: NSButton!

    @IBOutlet private var generateButton: NSButton!

    @IBOutlet private var autoRestoreCheckBox: NSButton!
    @IBOutlet private var transparentCheckBox: NSButton!
    @IBOutlet private var plainTextCheckBox: NSButton!
    @IBOutlet private var deleteDisplaySizeCheckBox: NSButton!
    @IBOutlet private var mergeOutputsCheckBox: NSButton!
    @IBOutlet private var keepPageSizeCheckBox: NSButton!
    @IBOutlet private var showOutputWindowCheckBox: NSButton!
    @IBOutlet private var sendNotificationCheckBox: NSButton!
    @IBOutlet private var previewCheckBox: NSButton!
    @IBOutlet private var deleteTmpFileCheckBox: NSButton!
    @IBOutlet private var toClipboardCheckBox: NSButton!
    @IBOutlet private var embedSourceCheckBox: NSButton!
    @IBOutlet private var autoPasteCheckBox: NSButton!
    @IBOutlet private var autoPasteDestinationPopUpButton: NSPopUpButton!
    @IBOutlet private var embedInIllustratorCheckBox: NSButton!
    @IBOutlet private var ungroupCheckBox: NSButton!
    @IBOutlet private var keepPageSizeAdvancedButton: NSButton!
    @IBOutlet private var mergeOutputAdvancedButton: NSButton!

    @IBOutlet private var preferenceWindow: NSWindow!

    @IBOutlet private var resolutionTextField: NSTextField!
    @IBOutlet private var dpiTextField: NSTextField!
    @IBOutlet private var leftMarginTextField: NSTextField!
    @IBOutlet private var rightMarginTextField: NSTextField!
    @IBOutlet private var topMarginTextField: NSTextField!
    @IBOutlet private var bottomMarginTextField: NSTextField!

    @IBOutlet private var resolutionStepper: NSStepper!
    @IBOutlet private var dpiStepper: NSStepper!
    @IBOutlet private var leftMarginStepper: NSStepper!
    @IBOutlet private var rightMarginStepper: NSStepper!
    @IBOutlet private var topMarginStepper: NSStepper!
    @IBOutlet private var bottomMarginStepper: NSStepper!

    @IBOutlet private var latexPathTextField: NSTextField!
    @IBOutlet private var dviDriverPathTextField: NSTextField!
    @IBOutlet private var gsPathTextField: NSTextField!
    @IBOutlet private var guessCompilationButton: NSButton!
    @IBOutlet private var numberOfCompilationTextField: NSTextField!
    @IBOutlet private var numberOfCompilationStepper: NSStepper!
    @IBOutlet private var textPdfCheckBox: NSButton!
    @IBOutlet private var ignoreErrorCheckBox: NSButton!
    @IBOutlet private var utfExportCheckBox: NSButton!
    @IBOutlet private var encodingPopUpButton: NSPopUpButton!
    @IBOutlet private var unitMatrix: NSMatrix!
    @IBOutlet private var priorityMatrix: NSMatrix!
    @IBOutlet private var workInInputFileDirectoryCheckBox: NSButton!

    @IBOutlet private var fillColorWell: NSColorWell!

    @IBOutlet private var lightModeForegroundColorWell: NSColorWell!
    @IBOutlet private var lightModeBackgroundColorWell: NSColorWell!
    @IBOutlet private var lightModeCursorColorWell: NSColorWell!
    @IBOutlet private var lightModeBraceColorWell: NSColorWell!
    @IBOutlet private var lightModeCommentColorWell: NSColorWell!
    @IBOutlet private var lightModeCommandColorWell: NSColorWell!
    @IBOutlet private var lightModeInvisibleColorWell: NSColorWell!
    @IBOutlet private var lightModeHighlightedBraceColorWell: NSColorWell!
    @IBOutlet private var lightModeEnclosedContentBackgroundColorWell: NSColorWell!
    @IBOutlet private var lightModeFlashingBackgroundColorWell: NSColorWell!
    @IBOutlet private var lightModeConsoleForegroundColorWell: NSColorWell!
    @IBOutlet private var lightModeConsoleBackgroundColorWell: NSColorWell!

    @IBOutlet private var darkModeForegroundColorWell: NSColorWell!
    @IBOutlet private var darkModeBackgroundColorWell: NSColorWell!
    @IBOutlet private var darkModeCursorColorWell: NSColorWell!
    @IBOutlet private var darkModeBraceColorWell: NSColorWell!
    @IBOutlet private var darkModeCommentColorWell: NSColorWell!
    @IBOutlet private var darkModeCommandColorWell: NSColorWell!
    @IBOutlet private var darkModeInvisibleColorWell: NSColorWell!
    @IBOutlet private var darkModeHighlightedBraceColorWell: NSColorWell!
    @IBOutlet private var darkModeEnclosedContentBackgroundColorWell: NSColorWell!
    @IBOutlet private var darkModeFlashingBackgroundColorWell: NSColorWell!
    @IBOutlet private var darkModeConsoleForegroundColorWell: NSColorWell!
    @IBOutlet private var darkModeConsoleBackgroundColorWell: NSColorWell!

    @IBOutlet private var makeatletterEnabledCheckBox: NSButton!

    @IBOutlet private var autoDetectionTargetSettingViewController: NSViewController!
    @IBOutlet private var autoDetectionTargetMatrix: NSMatrix!

    @IBOutlet private var invisibleCharacterBox: NSBox!

    @IBOutlet private var spaceCharacterKindButton: NSButton!
    @IBOutlet private var fullwidthSpaceCharacterKindButton: NSButton!
    @IBOutlet private var returnCharacterKindButton: NSButton!
    @IBOutlet private var tabCharacterKindButton: NSButton!

    @IBOutlet private var spaceCharacterKindSettingViewController: NSViewController!
    @IBOutlet private var spaceCharacterKindMatrix: NSMatrix!

    @IBOutlet private var fullwidthSpaceCharacterKindSettingViewController: NSViewController!
    @IBOutlet private var fullwidthSpaceCharacterKindMatrix: NSMatrix!

    @IBOutlet private var returnCharacterKindSettingViewController: NSViewController!
    @IBOutlet private var returnCharacterKindMatrix: NSMatrix!

    @IBOutlet private var tabCharacterKindSettingViewController: NSViewController!
    @IBOutlet private var tabCharacterKindMatrix: NSMatrix!

    @IBOutlet private var pageBoxSettingViewController: NSViewController!
    @IBOutlet private var pageBoxMatrix: NSMatrix!

    @IBOutlet private var animationParameterSettingViewController: NSViewController!
    @IBOutlet private var delayTextField: NSTextField!
    @IBOutlet private var delayStepper: NSStepper!
    @IBOutlet private var loopCountTextField: NSTextField!
    @IBOutlet private var loopCountStepper: NSStepper!

    @IBOutlet private var cuiToolInstallButton: NSButton!
    @IBOutlet private var cuiToolStatusView: NSImageView!
    @IBOutlet private var cuiToolStatusTextField: NSTextField!

    private var lastSavedPath: String?
    private var lastActiveWindow: NSWindow?
    private var lastColorDict: [String: Any] = [:]
    private var converter: Converter?
    private var runningTask: Process?
    private var outputPipe: Pipe?
    private var taskKilled = false
    private var sourceFont: NSFont?
    private var userNotificationDelegate: UserNotificationDelegate?
    private var notificationObservers = [NSObjectProtocol]()
    private var outputDataObserver: NSObjectProtocol?

    private func observeNotification(forName name: Notification.Name,
                                     object: Any? = nil,
                                     handler: @escaping (Notification) -> Void) {
        let token = NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { notification in
            handler(notification)
        }
        notificationObservers.append(token)
    }

    // MARK: - Sudo / Process helpers

    private func sudoCommand(_ command: String,
                             atDirectory path: String,
                             withArguments arguments: [String],
                             stdoutString output: AutoreleasingUnsafeMutablePointer<NSString?>,
                             errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        let arg = arguments.joined(separator: " ")
        let shellscript = "cd '\(path)'; '\(command)' \(arg)".replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(shellscript)\" with administrator privileges"
        var errorInfo: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let eventResult = appleScript?.executeAndReturnError(&errorInfo)

        guard let eventResult else {
            errorDescription.pointee = nil
            if let errorNumber = errorInfo?[NSAppleScript.errorNumber] as? NSNumber,
               errorNumber.intValue == -128 {
                errorDescription.pointee = NSLocalizedString("Admin password required", comment: "") as NSString
            }
            if errorDescription.pointee == nil,
               let message = errorInfo?[NSAppleScript.errorMessage] as? String {
                errorDescription.pointee = message as NSString
            }
            return false
        }

        output.pointee = eventResult.stringValue as NSString?
        return true
    }

    // MARK: - OutputController

    private func performOnMainThread(waitUntilDone: Bool = true, _ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else if waitUntilDone {
            DispatchQueue.main.sync(execute: work)
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    func exitCurrentThreadIfTaskKilled() {
        if taskKilled {
            taskKilled = false
            Thread.current.cancel()
            appendOutputAndScroll(String(format: "\n\nTeX2img: %@\n\n", NSLocalizedString("processAborted", comment: "")), quiet: false)
        }

        if Thread.current.isCancelled {
            generationDidFinish(.aborted)
            Thread.exit()
        }
    }

    func execCommand(_ command: String,
                     atDirectory path: String,
                     withArguments arguments: [String],
                     quiet: Bool) -> Bool {
        exitCurrentThreadIfTaskKilled()

        var cmdline = command + " "
        for argument in arguments {
            cmdline += argument + " "
        }
        cmdline += "2>&1"
        appendOutputAndScroll(String(format: "$ %@\n", cmdline), quiet: quiet)

        let task = Process()
        let pipe = Pipe()
        outputPipe = pipe
        runningTask = task

        task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
        task.currentDirectoryURL = URL(fileURLWithPath: path)
        task.executableURL = URL(fileURLWithPath: command)
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = arguments
        taskKilled = false

        pipe.fileHandleForReading.readInBackgroundAndNotify()

        do {
            try task.run()
        } catch {
            return false
        }

        task.waitUntilExit()
        appendOutputAndScroll("\n", quiet: quiet)
        exitCurrentThreadIfTaskKilled()
        return task.terminationStatus == 0
    }

    func showMainWindow() {
        DispatchQueue.main.async {
            self.mainWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func refreshTextView(_ textView: NSTextView,
                                 foregroundColor: NSColor?,
                                 backgroundColor: NSColor?,
                                 cursorColor: NSColor?) {
        var foregroundColor = foregroundColor
        var backgroundColor = backgroundColor
        var cursorColor = cursorColor

        if foregroundColor == nil { foregroundColor = .defaultForegroundColor }
        if backgroundColor == nil { backgroundColor = .defaultBackgroundColor }
        if cursorColor == nil { cursorColor = .defaultCursorColor }

        textView.textColor = foregroundColor!
        textView.backgroundColor = backgroundColor!
        textView.insertionPointColor = cursorColor!

        let entireRange = NSRange(location: 0, length: textView.string.count)
        textView.textStorage?.setAttributes([
            .foregroundColor: foregroundColor!,
            .backgroundColor: backgroundColor!
        ], range: entireRange)
    }

    private func appendOutputOnMainThread(_ str: String) {
        outputTextView.textStorage?.mutableString.append(str)

        let profile = currentProfile()
        refreshTextView(outputTextView,
                        foregroundColor: UtilityG.consoleForegroundColor(inProfile: profile),
                        backgroundColor: UtilityG.consoleBackgroundColor(inProfile: profile),
                        cursorColor: UtilityG.cursorColor(inProfile: profile))

        outputTextView.scrollRangeToVisible(NSRange(location: outputTextView.string.count, length: 0))
        outputTextView.font = sourceFont
    }

    func appendOutputAndScroll(_ str: String, quiet: Bool) {
        guard !quiet, !str.isEmpty else { return }
        performOnMainThread { self.appendOutputOnMainThread(str) }
    }

    func prepareOutputTextView() {
        outputDataObserver = NotificationCenter.default.addObserver(
            forName: FileHandle.readCompletionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.readOutputData(notification)
        }
    }

    func releaseOutputTextView() {
        if let outputDataObserver {
            NotificationCenter.default.removeObserver(outputDataObserver)
            self.outputDataObserver = nil
        }
    }

    private func presentOutputWindow() {
        if mainWindow.isInFullScreenMode {
            outputWindow.makeKeyAndOrderFront(nil)
            return
        }

        if outputWindow.isVisible {
            outputWindow.makeKeyAndOrderFront(nil)
            return
        }

        outputWindowMenuItem.state = .on

        let outputWindowRect = outputWindow.frame
        let screen = mainWindow.screen ?? NSScreen.main!
        let outputWindowNewOriginY = max(mainWindow.frame.minY, screen.visibleFrame.minY)
        let outputWindowNewHeight = max(mainWindow.frame.maxY - outputWindowNewOriginY, outputWindow.minSize.height)

        var newRect = NSRect(x: mainWindow.frame.maxX,
                             y: outputWindowNewOriginY,
                             width: outputWindowRect.width,
                             height: outputWindowNewHeight)

        if newRect.maxX <= screen.visibleFrame.maxX {
            outputWindow.setFrame(newRect, display: false)
        } else {
            newRect = NSRect(x: mainWindow.frame.minX - outputWindowRect.width,
                             y: outputWindowNewOriginY,
                             width: outputWindowRect.width,
                             height: outputWindowNewHeight)

            if screen.visibleFrame.minX <= newRect.minX {
                outputWindow.setFrame(newRect, display: false)
            } else {
                let newWidth = max(screen.visibleFrame.maxX - outputWindowRect.width - mainWindow.frame.minX - 1,
                                   mainWindow.minSize.width)
                newRect = NSRect(x: mainWindow.frame.minX,
                                 y: mainWindow.frame.minY,
                                 width: newWidth,
                                 height: mainWindow.frame.height)
                mainWindow.setFrame(newRect, display: true, animate: true)

                newRect = NSRect(x: mainWindow.frame.maxX,
                                 y: outputWindowNewOriginY,
                                 width: screen.visibleFrame.maxX - mainWindow.frame.maxX,
                                 height: outputWindowNewHeight)
                outputWindow.setFrame(newRect, display: false)
            }
        }

        outputWindow.makeKeyAndOrderFront(nil)
    }

    func showOutputWindow() {
        performOnMainThread { self.presentOutputWindow() }
    }

    func showExtensionError() {
        performOnMainThread {
            UtilityG.runErrorPanel(message: NSLocalizedString("extensionErrMsg", comment: ""))
        }
    }

    func showNotFoundError(_ aPath: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("programNotFoundErrorMsg", comment: ""), aPath))
        }
    }

    func latexExists(atPath latexPath: String, dviDriverPath: String, gsPath: String) -> Bool {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: latexPath.programPath) {
            showNotFoundError(latexPath)
            return false
        }
        if !fileManager.fileExists(atPath: dviDriverPath.programPath) {
            showNotFoundError(dviDriverPath)
            return false
        }
        if !fileManager.fileExists(atPath: gsPath.programPath) {
            showNotFoundError(gsPath)
            return false
        }
        return true
    }

    func epstopdfExists() -> Bool { true }
    func mudrawExists() -> Bool { true }
    func pdftopsExists() -> Bool { true }

    func showFileFormatError(_ aPath: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("fileFormatErrorMsg", comment: ""), aPath))
        }
    }

    func showFileGenerationError(_ aPath: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("fileGenerationErrorMsg", comment: ""), aPath))
        }
    }

    func showExecError(_ command: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("execErrorMsg", comment: ""), command))
        }
    }

    func showCannotOverwriteError(_ path: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotOverwriteErrorMsg", comment: ""), path))
        }
    }

    func showCannotCreateDirectoryError(_ dir: String) {
        performOnMainThread {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotCreateDirectoryErrorMsg", comment: ""), dir))
        }
    }

    func showCompileError() {
        performOnMainThread {
            UtilityG.runErrorPanel(message: NSLocalizedString("compileErrorMsg", comment: ""))
        }
    }

    func showImageSizeError() {
        performOnMainThread {
            UtilityG.runErrorPanel(message: NSLocalizedString("imageSizeErrorMsg", comment: ""))
        }
    }

    func showErrorsIgnoredWarning() {
        performOnMainThread {
            UtilityG.runWarningPanel(message: NSLocalizedString("errorsIgnoredWarning", comment: ""))
        }
    }

    func showPageSkippedWarning(_ pages: [Int]) {
        appendOutputAndScroll(String(format: "TeX2img: [%@] ", NSLocalizedString("Warning", comment: "")), quiet: false)
        if pages.count > 1 {
            appendOutputAndScroll(String(format: NSLocalizedString("pagesSkippedWarning", comment: ""),
                                         pages.map(String.init).joined(separator: ", ")), quiet: false)
        } else if let page = pages.first {
            appendOutputAndScroll(String(format: NSLocalizedString("pageSkippedWarning", comment: ""), page), quiet: false)
        }
        appendOutputAndScroll("\n", quiet: false)
    }

    func showWhitePageWarning(_ pages: [Int]) {
        appendOutputAndScroll(String(format: "TeX2img: [%@] ", NSLocalizedString("Warning", comment: "")), quiet: false)
        if pages.count > 1 {
            appendOutputAndScroll(String(format: NSLocalizedString("whitePagesWarning", comment: ""),
                                         pages.map(String.init).joined(separator: ", ")), quiet: false)
        } else if let page = pages.first {
            appendOutputAndScroll(String(format: NSLocalizedString("whitePageWarning", comment: ""), page), quiet: false)
        }
        appendOutputAndScroll("\n", quiet: false)
    }

    private func previewFilesOnMainThread(_ files: [String], app: String) {
        if app == SVG_PREVIEWER && !FileManager.default.fileExists(atPath: SVG_PREVIEWER) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Warning", comment: "")
            alert.informativeText = NSLocalizedString("Gapplin required", comment: "")
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: NSLocalizedString("Open in App Store", comment: ""))
            let result = alert.runModal()
            if result == .alertSecondButtonReturn {
                NSWorkspace.shared.open(URL(string: GAPPLIN_URL)!)
            }
        } else {
            Utility.previewFiles(files, app: app)
        }
    }

    func previewFiles(_ files: [String], withApplication app: String) {
        performOnMainThread(waitUntilDone: false) {
            self.previewFilesOnMainThread(files, app: app)
        }
    }

    func printResult(_ generatedFiles: [String], quiet: Bool) {
        let count = generatedFiles.count
        if count > 1 {
            appendOutputAndScroll(String(format: "TeX2img: %@\n",
                                         String(format: NSLocalizedString("generatedFilesMessage", comment: ""), count)), quiet: quiet)
        } else {
            appendOutputAndScroll(String(format: "TeX2img: %@\n",
                                         String(format: NSLocalizedString("generatedFileMessage", comment: ""), count)), quiet: quiet)
        }
    }

    // MARK: - Profile helpers

    private func loadStringSetting(for textField: NSTextField, from profile: Profile, key: String) {
        if let tempStr = profile.stringForKey(key) {
            textField.stringValue = tempStr
            outputFilePathChanged(nil)
        }
    }

    private func loadNumberSetting(for textField: NSTextField, from profile: Profile, key: String) {
        if let tempNumber = profile[key] as? NSNumber {
            textField.floatValue = tempNumber.floatValue
        }
    }

    private func loadSetting(for textView: NSTextView, from profile: Profile, key: String) {
        if let tempStr = profile.stringForKey(key) {
            textView.textStorage?.mutableString.setString(tempStr)
        }
    }

    private func loadColorWell(_ well: NSColorWell, from profile: Profile, key: String, defaultColor: NSColor) {
        if profile.keys.contains(key) {
            well.color = profile.colorForKey(key) ?? defaultColor
        } else {
            well.color = defaultColor
        }
        well.saveColor(to: &lastColorDict)
    }

    func adoptProfile(_ aProfile: Profile) {
        guard aProfile.count > 0 else { return }
        let keys = Array(aProfile.keys)

        loadStringSetting(for: outputFileTextField, from: aProfile, key: OutputFileKey)

        if keys.contains(AutoRestoreSourceKey) {
            autoRestoreCheckBox.state = aProfile.integerForKey(AutoRestoreSourceKey) == 0 ? .off : .on
        } else {
            autoRestoreCheckBox.state = .on
        }

        showOutputWindowCheckBox.state = aProfile.integerForKey(ShowOutputWindowKey) == 0 ? .off : .on
        sendNotificationCheckBox.state = aProfile.integerForKey(SendNotificationKey) == 0 ? .off : .on
        previewCheckBox.state = aProfile.integerForKey(PreviewKey) == 0 ? .off : .on
        deleteTmpFileCheckBox.state = aProfile.integerForKey(DeleteTmpFileKey) == 0 ? .off : .on

        if keys.contains(EmbedSourceKey) {
            embedSourceCheckBox.state = aProfile.integerForKey(EmbedSourceKey) == 0 ? .off : .on
        } else {
            embedSourceCheckBox.state = .on
        }

        toClipboardCheckBox.state = aProfile.integerForKey(CopyToClipboardKey) == 0 ? .off : .on
        autoPasteCheckBox.state = aProfile.integerForKey(AutoPasteKey) == 0 ? .off : .on

        var autoPasteDestinationTag = aProfile.integerForKey(AutoPasteDestinationKey)
        if autoPasteDestinationTag == 0 { autoPasteDestinationTag = 1 }
        autoPasteDestinationPopUpButton.selectItem(withTag: autoPasteDestinationTag)

        embedInIllustratorCheckBox.state = aProfile.integerForKey(EmbedInIllustratorKey) == 0 ? .off : .on
        ungroupCheckBox.state = aProfile.integerForKey(UngroupKey) == 0 ? .off : .on
        transparentCheckBox.state = aProfile.boolForKey(TransparentKey) ? .on : .off
        plainTextCheckBox.state = aProfile.boolForKey(PlainTextKey) ? .on : .off
        textPdfCheckBox.state = aProfile.boolForKey(GetOutlineKey) ? .off : .on
        deleteDisplaySizeCheckBox.state = aProfile.boolForKey(DeleteDisplaySizeKey) ? .on : .off
        mergeOutputsCheckBox.state = aProfile.boolForKey(MergeOutputsKey) ? .on : .off
        keepPageSizeCheckBox.state = aProfile.boolForKey(KeepPageSizeKey) ? .on : .off
        ignoreErrorCheckBox.state = aProfile.boolForKey(IgnoreErrorKey) ? .on : .off
        utfExportCheckBox.state = aProfile.boolForKey(UtfExportKey) ? .on : .off
        workInInputFileDirectoryCheckBox.state = aProfile.integerForKey(WorkingDirectoryTypeKey) == WorkingDirectoryFile ? .on : .off

        convertYenMarkMenuItem.state = aProfile.boolForKey(ConvertYenMarkKey) ? .on : .off
        richTextMenuItem.state = aProfile.boolForKey(RichTextKey) ? .on : .off
        flashInMovingCheckBox.state = aProfile.boolForKey(FlashInMovingKey) ? .on : .off
        highlightContentCheckBox.state = aProfile.boolForKey(HighlightContentKey) ? .on : .off
        beepCheckBox.state = aProfile.boolForKey(BeepKey) ? .on : .off
        flashBackgroundCheckBox.state = aProfile.boolForKey(FlashBackgroundKey) ? .on : .off
        checkBraceCheckBox.state = aProfile.boolForKey(CheckBraceKey) ? .on : .off
        checkBracketCheckBox.state = aProfile.boolForKey(CheckBracketKey) ? .on : .off
        checkSquareCheckBox.state = aProfile.boolForKey(CheckSquareBracketKey) ? .on : .off
        checkParenCheckBox.state = aProfile.boolForKey(CheckParenKey) ? .on : .off

        let tabWidth = aProfile.integerForKey(TabWidthKey)
        tabWidthTextField.integerValue = tabWidth > 0 ? tabWidth : 4
        tabWidthStepper.integerValue = tabWidthTextField.integerValue

        if keys.contains(TabIndentKey) {
            tabIndentCheckBox.state = aProfile.integerForKey(TabIndentKey) == 0 ? .off : .on
        } else {
            tabIndentCheckBox.state = .on
        }

        if keys.contains(WrapLineKey) {
            wrapLineCheckBox.state = aProfile.integerForKey(WrapLineKey) == 0 ? .off : .on
        } else {
            wrapLineCheckBox.state = .on
        }

        loadColorWell(fillColorWell, from: aProfile, key: FillColorKey, defaultColor: .white)

        loadColorWell(lightModeForegroundColorWell, from: aProfile, key: ForegroundColorForLightModeKey, defaultColor: .defaultForegroundColorForLightMode)
        loadColorWell(lightModeBackgroundColorWell, from: aProfile, key: BackgroundColorForLightModeKey, defaultColor: .defaultBackgroundColorForLightMode)
        loadColorWell(lightModeCursorColorWell, from: aProfile, key: CursorColorForLightModeKey, defaultColor: .defaultCursorColorForLightMode)
        loadColorWell(lightModeBraceColorWell, from: aProfile, key: BraceColorForLightModeKey, defaultColor: .defaultBraceColorForLightMode)
        loadColorWell(lightModeCommentColorWell, from: aProfile, key: CommentColorForLightModeKey, defaultColor: .defaultCommentColorForLightMode)
        loadColorWell(lightModeCommandColorWell, from: aProfile, key: CommandColorForLightModeKey, defaultColor: .defaultCommandColorForLightMode)
        loadColorWell(lightModeInvisibleColorWell, from: aProfile, key: InvisibleColorForLightModeKey, defaultColor: .defaultInvisibleColorForLightMode)
        loadColorWell(lightModeHighlightedBraceColorWell, from: aProfile, key: HighlightedBraceColorForLightModeKey, defaultColor: .defaultHighlightedBraceColorForLightMode)
        loadColorWell(lightModeEnclosedContentBackgroundColorWell, from: aProfile, key: EnclosedContentBackgroundColorForLightModeKey, defaultColor: .defaultEnclosedContentBackgroundColorForLightMode)
        loadColorWell(lightModeFlashingBackgroundColorWell, from: aProfile, key: FlashingBackgroundColorForLightModeKey, defaultColor: .defaultFlashingBackgroundColorForLightMode)
        loadColorWell(lightModeConsoleForegroundColorWell, from: aProfile, key: ConsoleForegroundColorForLightModeKey, defaultColor: .defaultConsoleForegroundColorForLightMode)
        loadColorWell(lightModeConsoleBackgroundColorWell, from: aProfile, key: ConsoleBackgroundColorForLightModeKey, defaultColor: .defaultConsoleBackgroundColorForLightMode)

        loadColorWell(darkModeForegroundColorWell, from: aProfile, key: ForegroundColorForDarkModeKey, defaultColor: .defaultForegroundColorForDarkMode)
        loadColorWell(darkModeBackgroundColorWell, from: aProfile, key: BackgroundColorForDarkModeKey, defaultColor: .defaultBackgroundColorForDarkMode)
        loadColorWell(darkModeCursorColorWell, from: aProfile, key: CursorColorForDarkModeKey, defaultColor: .defaultCursorColorForDarkMode)
        loadColorWell(darkModeBraceColorWell, from: aProfile, key: BraceColorForDarkModeKey, defaultColor: .defaultBraceColorForDarkMode)
        loadColorWell(darkModeCommentColorWell, from: aProfile, key: CommentColorForDarkModeKey, defaultColor: .defaultCommentColorForDarkMode)
        loadColorWell(darkModeCommandColorWell, from: aProfile, key: CommandColorForDarkModeKey, defaultColor: .defaultCommandColorForDarkMode)
        loadColorWell(darkModeInvisibleColorWell, from: aProfile, key: InvisibleColorForDarkModeKey, defaultColor: .defaultInvisibleColorForDarkMode)
        loadColorWell(darkModeHighlightedBraceColorWell, from: aProfile, key: HighlightedBraceColorForDarkModeKey, defaultColor: .defaultHighlightedBraceColorForDarkMode)
        loadColorWell(darkModeEnclosedContentBackgroundColorWell, from: aProfile, key: EnclosedContentBackgroundColorForDarkModeKey, defaultColor: .defaultEnclosedContentBackgroundColorForDarkMode)
        loadColorWell(darkModeFlashingBackgroundColorWell, from: aProfile, key: FlashingBackgroundColorForDarkModeKey, defaultColor: .defaultFlashingBackgroundColorForDarkMode)
        loadColorWell(darkModeConsoleForegroundColorWell, from: aProfile, key: ConsoleForegroundColorForDarkModeKey, defaultColor: .defaultConsoleForegroundColorForDarkMode)
        loadColorWell(darkModeConsoleBackgroundColorWell, from: aProfile, key: ConsoleBackgroundColorForDarkModeKey, defaultColor: .defaultConsoleBackgroundColorForDarkMode)

        if keys.contains(ColorPalleteColorKey) {
            colorPalleteColorWell.color = aProfile.colorForKey(ColorPalleteColorKey) ?? .red
        } else {
            colorPalleteColorWell.color = .red
        }
        colorPalleteColorWell.saveColor(to: &lastColorDict)

        if keys.contains(MakeatletterEnabledKey) {
            makeatletterEnabledCheckBox.state = aProfile.boolForKey(MakeatletterEnabledKey) ? .on : .off
        } else {
            makeatletterEnabledCheckBox.state = .on
        }

        autoCompleteMenuItem.state = aProfile.boolForKey(AutoCompleteKey) ? .on : .off
        autoIndentMenuItem.state = aProfile.boolForKey(AutoIndentKey) ? .on : .off
        showTabCharacterCheckBox.state = aProfile.boolForKey(ShowTabCharacterKey) ? .on : .off
        showSpaceCharacterCheckBox.state = aProfile.boolForKey(ShowSpaceCharacterKey) ? .on : .off
        showFullwidthSpaceCharacterCheckBox.state = aProfile.boolForKey(ShowFullwidthSpaceCharacterKey) ? .on : .off
        showNewLineCharacterCheckBox.state = aProfile.boolForKey(ShowNewLineCharacterKey) ? .on : .off
        guessCompilationButton.state = aProfile.boolForKey(GuessCompilationKey) ? .on : .off

        if let encoding = aProfile.stringForKey(EncodingKey) {
            var tag = EncodingTag.none
            if encoding == PTEX_ENCODING_UTF8 || encoding == "uptex" {
                tag = .utf8
            } else if encoding == PTEX_ENCODING_SJIS {
                tag = .sjis
            } else if encoding == PTEX_ENCODING_JIS {
                tag = .jis
            } else if encoding == PTEX_ENCODING_EUC {
                tag = .euc
            }
            encodingPopUpButton.selectItem(withTag: tag.rawValue)
        }

        loadStringSetting(for: latexPathTextField, from: aProfile, key: LatexPathKey)
        loadStringSetting(for: dviDriverPathTextField, from: aProfile, key: DviDriverPathKey)
        loadStringSetting(for: gsPathTextField, from: aProfile, key: GsPathKey)

        loadNumberSetting(for: resolutionTextField, from: aProfile, key: ResolutionKey)
        loadNumberSetting(for: dpiTextField, from: aProfile, key: DPIKey)
        loadNumberSetting(for: leftMarginTextField, from: aProfile, key: LeftMarginKey)
        loadNumberSetting(for: rightMarginTextField, from: aProfile, key: RightMarginKey)
        loadNumberSetting(for: topMarginTextField, from: aProfile, key: TopMarginKey)
        loadNumberSetting(for: bottomMarginTextField, from: aProfile, key: BottomMarginKey)

        resolutionStepper.floatValue = resolutionTextField.floatValue
        dpiStepper.floatValue = dpiTextField.floatValue
        leftMarginStepper.integerValue = leftMarginTextField.integerValue
        rightMarginStepper.integerValue = rightMarginTextField.integerValue
        topMarginStepper.integerValue = topMarginTextField.integerValue
        bottomMarginStepper.integerValue = bottomMarginTextField.integerValue

        numberOfCompilationTextField.integerValue = max(1, aProfile.integerForKey(NumberOfCompilationKey))
        numberOfCompilationStepper.integerValue = numberOfCompilationTextField.integerValue

        unitMatrix.selectCell(withTag: aProfile.integerForKey(UnitKey))
        priorityMatrix.selectCell(withTag: aProfile.integerForKey(PriorityKey))

        if keys.contains(AutoDetectionTargetKey) {
            autoDetectionTargetMatrix.selectCell(withTag: aProfile.integerForKey(AutoDetectionTargetKey))
        }
        if keys.contains(SpaceCharacterKindKey) {
            spaceCharacterKindMatrix.selectCell(withTag: aProfile.integerForKey(SpaceCharacterKindKey))
        }
        if keys.contains(FullwidthSpaceCharacterKindKey) {
            fullwidthSpaceCharacterKindMatrix.selectCell(withTag: aProfile.integerForKey(FullwidthSpaceCharacterKindKey))
        }
        if keys.contains(ReturnCharacterKindKey) {
            returnCharacterKindMatrix.selectCell(withTag: aProfile.integerForKey(ReturnCharacterKindKey))
        }
        if keys.contains(TabCharacterKindKey) {
            tabCharacterKindMatrix.selectCell(withTag: aProfile.integerForKey(TabCharacterKindKey))
        }
        if keys.contains(PageBoxKey) {
            pageBoxMatrix.selectCell(withTag: aProfile.integerForKey(PageBoxKey))
        }
        if keys.contains(DelayKey) {
            delayTextField.floatValue = max(0, aProfile.floatForKey(DelayKey))
            delayStepper.floatValue = delayTextField.floatValue
        }
        if keys.contains(LoopCountKey) {
            loopCountTextField.integerValue = max(0, aProfile.integerForKey(LoopCountKey))
            loopCountStepper.integerValue = loopCountTextField.integerValue
        }
        if keys.contains(CommandCompletionKeyKey) {
            commandCompletionKeyMatrix.selectCell(withTag: aProfile.integerForKey(CommandCompletionKeyKey))
        }

        invisibleCharacterKindChanged(nil)
        loadSetting(for: preambleTextView, from: aProfile, key: PreambleKey)
        refreshOutputTextView(usingProfile: aProfile)

        if let fontName = aProfile.stringForKey(SourceFontNameKey),
           let aFont = NSFont(name: fontName, size: CGFloat(aProfile.floatForKey(SourceFontSizeKey))) {
            sourceFont = aFont
            sourceTextView.font = aFont
            preambleTextView.font = aFont
            outputTextView.font = aFont
            setupFontTextField(aFont)
        } else {
            loadDefaultFont()
        }

        sourceTextView.fixupTabs()
        sourceTextView.refreshWordWrap()
        preambleTextView.colorizeText()
        preambleTextView.fixupTabs()
        preambleTextView.refreshWordWrap()

        if let sourceFont {
            let displayFont = NSFont(name: sourceFont.fontName, size: spaceCharacterKindButton.font?.pointSize ?? sourceFont.pointSize)
            setInvisibleCharacterFont(displayFont)
        }

        if let inputSourceFilePath = aProfile.stringForKey(InputSourceFilePathKey) {
            inputSourceFileTextField.stringValue = inputSourceFilePath
        }

        switch InputMethod(rawValue: aProfile.integerForKey(InputMethodKey)) ?? .direct {
        case .direct:
            sourceSettingChanged(directInputButton)
        case .fromFile:
            sourceSettingChanged(inputSourceFileButton)
        }
    }

    func refreshOutputTextView(usingProfile aProfile: Profile?) {
        let profile = aProfile ?? currentProfile()
        refreshTextView(outputTextView,
                        foregroundColor: UtilityG.consoleForegroundColor(inProfile: profile),
                        backgroundColor: UtilityG.consoleBackgroundColor(inProfile: profile),
                        cursorColor: UtilityG.cursorColor(inProfile: profile))
    }

    private func setInvisibleCharacterFont(_ font: NSFont?) {
        guard let font else { return }
        spaceCharacterKindMatrix.setCellFont(font)
        fullwidthSpaceCharacterKindMatrix.setCellFont(font)
        returnCharacterKindMatrix.setCellFont(font)
        tabCharacterKindMatrix.setCellFont(font)
        spaceCharacterKindButton.font = font
        fullwidthSpaceCharacterKindButton.font = font
        returnCharacterKindButton.font = font
        tabCharacterKindButton.font = font
    }

    private func adoptProfileDuringLauching() -> Bool {
        guard let aProfile = profileController.profileForName(autoSavedProfileName) else { return false }
        adoptProfile(aProfile)

        let x = aProfile.floatForKey(XKey)
        let y = aProfile.floatForKey(YKey)
        let mainWindowWidth = aProfile.floatForKey(MainWindowWidthKey)
        let mainWindowHeight = aProfile.floatForKey(MainWindowHeightKey)

        if x != 0 && y != 0 && mainWindowWidth != 0 && mainWindowHeight != 0 {
            mainWindow.setFrame(NSRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(mainWindowWidth), height: CGFloat(mainWindowHeight)), display: true)
        }

        if aProfile.boolForKey(AutoRestoreSourceKey), let body = aProfile.stringForKey(SourceBodyKey) {
            sourceTextView.replaceEntireContents(with: body)
        }
        return true
    }

    func currentProfile() -> Profile {
        var currentProfile: Profile = [:]
        do {
            currentProfile[TeX2imgVersionKey] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
            currentProfile[XKey] = mainWindow.frame.minX
            currentProfile[YKey] = mainWindow.frame.minY
            currentProfile[MainWindowWidthKey] = mainWindow.frame.width
            currentProfile[MainWindowHeightKey] = mainWindow.frame.height
            currentProfile[OutputFileKey] = outputFileTextField.stringValue
            currentProfile[AutoRestoreSourceKey] = autoRestoreCheckBox.state.rawValue
            currentProfile[ShowOutputWindowKey] = showOutputWindowCheckBox.state.rawValue
            currentProfile[SendNotificationKey] = sendNotificationCheckBox.state.rawValue
            currentProfile[PreviewKey] = previewCheckBox.state.rawValue
            currentProfile[DeleteTmpFileKey] = deleteTmpFileCheckBox.state.rawValue
            currentProfile[EmbedSourceKey] = embedSourceCheckBox.state.rawValue
            currentProfile[CopyToClipboardKey] = toClipboardCheckBox.state.rawValue
            currentProfile[AutoPasteKey] = autoPasteCheckBox.state.rawValue
            currentProfile[AutoPasteDestinationKey] = autoPasteDestinationPopUpButton.selectedTag()
            currentProfile[EmbedInIllustratorKey] = embedInIllustratorCheckBox.state.rawValue
            currentProfile[UngroupKey] = ungroupCheckBox.state.rawValue
            currentProfile[TransparentKey] = transparentCheckBox.state.rawValue
            currentProfile[PlainTextKey] = plainTextCheckBox.state.rawValue
            currentProfile[GetOutlineKey] = textPdfCheckBox.state == .off
            currentProfile[DeleteDisplaySizeKey] = deleteDisplaySizeCheckBox.state.rawValue
            currentProfile[MergeOutputsKey] = mergeOutputsCheckBox.state.rawValue
            currentProfile[KeepPageSizeKey] = keepPageSizeCheckBox.state.rawValue
            currentProfile[IgnoreErrorKey] = ignoreErrorCheckBox.state.rawValue
            currentProfile[UtfExportKey] = utfExportCheckBox.state.rawValue
            currentProfile[LatexPathKey] = latexPathTextField.stringValue
            currentProfile[DviDriverPathKey] = dviDriverPathTextField.stringValue
            currentProfile[GsPathKey] = gsPathTextField.stringValue
            currentProfile[GuessCompilationKey] = guessCompilationButton.state.rawValue
            currentProfile[NumberOfCompilationKey] = numberOfCompilationTextField.integerValue
            currentProfile[ResolutionKey] = resolutionTextField.floatValue
            currentProfile[DPIKey] = dpiTextField.floatValue
            currentProfile[LeftMarginKey] = leftMarginTextField.integerValue
            currentProfile[RightMarginKey] = rightMarginTextField.integerValue
            currentProfile[TopMarginKey] = topMarginTextField.integerValue
            currentProfile[BottomMarginKey] = bottomMarginTextField.integerValue

            let tabWidth = tabWidthTextField.integerValue
            currentProfile[TabWidthKey] = tabWidth > 0 ? tabWidth : 4
            currentProfile[TabIndentKey] = tabIndentCheckBox.state.rawValue
            currentProfile[WrapLineKey] = wrapLineCheckBox.state.rawValue
            currentProfile[UnitKey] = unitMatrix.selectedTag()
            currentProfile[PriorityKey] = priorityMatrix.selectedTag()
            currentProfile[CommandCompletionKeyKey] = commandCompletionKeyMatrix.selectedTag()
            currentProfile[AutoDetectionTargetKey] = autoDetectionTargetMatrix.selectedTag()
            currentProfile[SpaceCharacterKindKey] = spaceCharacterKindMatrix.selectedTag()
            currentProfile[FullwidthSpaceCharacterKindKey] = fullwidthSpaceCharacterKindMatrix.selectedTag()
            currentProfile[ReturnCharacterKindKey] = returnCharacterKindMatrix.selectedTag()
            currentProfile[TabCharacterKindKey] = tabCharacterKindMatrix.selectedTag()
            currentProfile[PageBoxKey] = pageBoxMatrix.selectedTag()
            currentProfile[DelayKey] = delayTextField.floatValue
            currentProfile[LoopCountKey] = loopCountTextField.integerValue
            currentProfile[ConvertYenMarkKey] = convertYenMarkMenuItem.state.rawValue
            currentProfile[RichTextKey] = richTextMenuItem.state.rawValue
            currentProfile[FlashInMovingKey] = flashInMovingCheckBox.state.rawValue
            currentProfile[HighlightContentKey] = highlightContentCheckBox.state.rawValue
            currentProfile[BeepKey] = beepCheckBox.state.rawValue
            currentProfile[FlashBackgroundKey] = flashBackgroundCheckBox.state.rawValue
            currentProfile[CheckBraceKey] = checkBraceCheckBox.state.rawValue
            currentProfile[CheckBracketKey] = checkBracketCheckBox.state.rawValue
            currentProfile[CheckSquareBracketKey] = checkSquareCheckBox.state.rawValue
            currentProfile[CheckParenKey] = checkParenCheckBox.state.rawValue
            currentProfile[AutoCompleteKey] = autoCompleteMenuItem.state.rawValue
            currentProfile[AutoIndentKey] = autoIndentMenuItem.state.rawValue
            currentProfile[ShowTabCharacterKey] = showTabCharacterCheckBox.state.rawValue
            currentProfile[ShowSpaceCharacterKey] = showSpaceCharacterCheckBox.state.rawValue
            currentProfile[ShowFullwidthSpaceCharacterKey] = showFullwidthSpaceCharacterCheckBox.state.rawValue
            currentProfile[ShowNewLineCharacterKey] = showNewLineCharacterCheckBox.state.rawValue
            currentProfile[SourceFontNameKey] = sourceFont?.fontName
            currentProfile[SourceFontSizeKey] = sourceFont?.pointSize ?? 0
            currentProfile[PreambleKey] = preambleTextView.textStorage?.string ?? ""
            currentProfile[SourceBodyKey] = sourceTextView.textStorage?.string ?? ""
            currentProfile[InputMethodKey] = directInputButton.state == .on ? InputMethod.direct.rawValue : InputMethod.fromFile.rawValue
            currentProfile[InputSourceFilePathKey] = inputSourceFileTextField.stringValue
            currentProfile[WorkingDirectoryTypeKey] = workInInputFileDirectoryCheckBox.state == .on ? WorkingDirectoryFile : WorkingDirectoryTmp

            let workingDirectoryType = currentProfile.integerForKey(WorkingDirectoryTypeKey)
            let inputMethod = currentProfile.integerForKey(InputMethodKey)
            if workingDirectoryType == WorkingDirectoryFile && inputMethod == InputMethod.fromFile.rawValue {
                currentProfile[WorkingDirectoryPathKey] = currentProfile.stringForKey(InputSourceFilePathKey)?.deletingLastPathComponent
            } else {
                currentProfile[WorkingDirectoryPathKey] = FileManager.default.temporaryDirectory.path
            }

            currentProfile[FillColorKey] = fillColorWell.color.serializedString
            currentProfile[ForegroundColorForLightModeKey] = lightModeForegroundColorWell.color.serializedString
            currentProfile[BackgroundColorForLightModeKey] = lightModeBackgroundColorWell.color.serializedString
            currentProfile[CursorColorForLightModeKey] = lightModeCursorColorWell.color.serializedString
            currentProfile[BraceColorForLightModeKey] = lightModeBraceColorWell.color.serializedString
            currentProfile[CommentColorForLightModeKey] = lightModeCommentColorWell.color.serializedString
            currentProfile[CommandColorForLightModeKey] = lightModeCommandColorWell.color.serializedString
            currentProfile[InvisibleColorForLightModeKey] = lightModeInvisibleColorWell.color.serializedString
            currentProfile[HighlightedBraceColorForLightModeKey] = lightModeHighlightedBraceColorWell.color.serializedString
            currentProfile[EnclosedContentBackgroundColorForLightModeKey] = lightModeEnclosedContentBackgroundColorWell.color.serializedString
            currentProfile[FlashingBackgroundColorForLightModeKey] = lightModeFlashingBackgroundColorWell.color.serializedString
            currentProfile[ConsoleForegroundColorForLightModeKey] = lightModeConsoleForegroundColorWell.color.serializedString
            currentProfile[ConsoleBackgroundColorForLightModeKey] = lightModeConsoleBackgroundColorWell.color.serializedString
            currentProfile[ForegroundColorForDarkModeKey] = darkModeForegroundColorWell.color.serializedString
            currentProfile[BackgroundColorForDarkModeKey] = darkModeBackgroundColorWell.color.serializedString
            currentProfile[CursorColorForDarkModeKey] = darkModeCursorColorWell.color.serializedString
            currentProfile[BraceColorForDarkModeKey] = darkModeBraceColorWell.color.serializedString
            currentProfile[CommentColorForDarkModeKey] = darkModeCommentColorWell.color.serializedString
            currentProfile[CommandColorForDarkModeKey] = darkModeCommandColorWell.color.serializedString
            currentProfile[InvisibleColorForDarkModeKey] = darkModeInvisibleColorWell.color.serializedString
            currentProfile[HighlightedBraceColorForDarkModeKey] = darkModeHighlightedBraceColorWell.color.serializedString
            currentProfile[EnclosedContentBackgroundColorForDarkModeKey] = darkModeEnclosedContentBackgroundColorWell.color.serializedString
            currentProfile[FlashingBackgroundColorForDarkModeKey] = darkModeFlashingBackgroundColorWell.color.serializedString
            currentProfile[ConsoleForegroundColorForDarkModeKey] = darkModeConsoleForegroundColorWell.color.serializedString
            currentProfile[ConsoleBackgroundColorForDarkModeKey] = darkModeConsoleBackgroundColorWell.color.serializedString
            currentProfile[MakeatletterEnabledKey] = makeatletterEnabledCheckBox.state.rawValue
            currentProfile[ColorPalleteColorKey] = colorPalleteColorWell.color.serializedString
        }

        switch encodingPopUpButton.selectedTag() {
        case EncodingTag.utf8.rawValue:
            currentProfile[EncodingKey] = PTEX_ENCODING_UTF8
        case EncodingTag.sjis.rawValue:
            currentProfile[EncodingKey] = PTEX_ENCODING_SJIS
        case EncodingTag.jis.rawValue:
            currentProfile[EncodingKey] = PTEX_ENCODING_JIS
        case EncodingTag.euc.rawValue:
            currentProfile[EncodingKey] = PTEX_ENCODING_EUC
        default:
            currentProfile[EncodingKey] = PTEX_ENCODING_NONE
        }

        return currentProfile
    }

    // MARK: - Templates

    private func addTemplateMenuItem(_ filename: String, atDirectory directory: String, to menu: NSMenu, at index: NSNumber?) {
        let fileManager = FileManager.default
        let fullPath = directory.appendingPathComponent(filename)

        if filename.pathExtension == "tex" {
            let title = filename.deletingPathExtension
            let menuItem = NSMenuItem(title: title, action: #selector(adoptPreambleTemplate(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.toolTip = fullPath
            if let index {
                menu.insertItem(menuItem, at: index.intValue)
            } else {
                menu.addItem(menuItem)
            }
        }

        if fileManager.isDirectory(atPath: fullPath) {
            let itemWithSubmenu = NSMenuItem(title: filename, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            submenu.autoenablesItems = false
            constructTemplatePopupRecursively(atDirectory: directory.appendingPathComponent(filename), parentMenu: submenu)
            itemWithSubmenu.submenu = submenu
            if let index {
                menu.insertItem(itemWithSubmenu, at: index.intValue)
            } else {
                menu.addItem(itemWithSubmenu)
            }
        }
    }

    private func constructTemplatePopup(_ sender: Any) {
        guard let menu = templatePopupButton.menu else { return }
        while menu.numberOfItems > 5 {
            menu.removeItem(at: 1)
        }

        let templateDirectoryPath = self.templateDirectoryPath
        guard let filenames = try? FileManager.default.contentsOfDirectory(atPath: templateDirectoryPath) else { return }
        for filename in filenames.reversed() {
            addTemplateMenuItem(filename, atDirectory: templateDirectoryPath, to: menu, at: 1)
        }
    }

    private func constructTemplatePopupRecursively(atDirectory directory: String, parentMenu menu: NSMenu) {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory) else { return }
        for filename in files {
            addTemplateMenuItem(filename, atDirectory: directory, to: menu, at: nil)
        }
    }

    @IBAction func adoptPreambleTemplate(_ sender: Any) {
        let templatePath: String?
        if let menuItem = sender as? NSMenuItem {
            templatePath = menuItem.toolTip
        } else if let path = sender as? String {
            templatePath = path
        } else {
            return
        }

        guard let templatePath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: templatePath)) else {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotReadErrorMsg", comment: ""), templatePath ?? ""))
            return
        }

        var detectedEncoding: UInt = 0
        guard let contents = String.stringWithAutoEncodingDetectionOfData(data, detectedEncoding: &detectedEncoding) else {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotReadErrorMsg", comment: ""), templatePath))
            return
        }

        let message = String(format: "%@\n\n%@", NSLocalizedString("resotrePreambleMsg", comment: ""), contents.replacingOccurrences(of: "%", with: "%%"))
        if UtilityG.runConfirmPanel(message: message) {
            preambleTextView.replaceEntireContents(with: contents)
        }
    }

    private var templateDirectoryPath: String {
        let applicationSupportDirectoryPath = FileManager.default.applicationSupportDirectory ?? FileManager.default.temporaryDirectory.path
        return applicationSupportDirectoryPath.appendingPathComponent(templateDirectoryName)
    }

    @IBAction func restoreDefaultTemplates(_ sender: Any) {
        if UtilityG.runConfirmPanel(message: NSLocalizedString("restoreTemplatesConfirmationMsg", comment: "")) {
            restoreDefaultTemplatesLogic()
        }
    }

    private func restoreDefaultTemplatesLogic() {
        let fileManager = FileManager.default
        let templateDirectoryPath = self.templateDirectoryPath
        guard let originalTemplateDirectory = Bundle.main.path(forResource: templateDirectoryName, ofType: nil) else { return }

        if !fileManager.fileExists(atPath: templateDirectoryPath) {
            try? fileManager.createDirectory(atPath: templateDirectoryPath, withIntermediateDirectories: true)
        }

        if let files = try? fileManager.contentsOfDirectory(atPath: originalTemplateDirectory) {
            for file in files {
                let src = originalTemplateDirectory.appendingPathComponent(file)
                let dst = templateDirectoryPath.appendingPathComponent(file)
                try? fileManager.removeItem(atPath: dst)
                try? fileManager.copyItem(atPath: src, toPath: dst)
            }
        }
    }

    // MARK: - Lifecycle / notifications

    override func awakeFromNib() {
        userNotificationDelegate = UserNotificationDelegate()
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().delegate = userNotificationDelegate
        } else {
            NSUserNotificationCenter.default.delegate = userNotificationDelegate
        }

        observeNotification(forName: NSApplication.didBecomeActiveNotification, object: NSApp) { [weak self] _ in
            self?.showMainWindow()
        }
        observeNotification(forName: NSApplication.willTerminateNotification, object: NSApp) { [weak self] _ in
            self?.applicationWillTerminate()
        }
        observeNotification(forName: NSWindow.willCloseNotification, object: outputWindow) { [weak self] _ in
            self?.uncheckOutputWindowMenuItem()
        }
        observeNotification(forName: NSWindow.willCloseNotification, object: preambleWindow) { [weak self] _ in
            self?.uncheckPreambleWindowMenuItem()
        }
        observeNotification(forName: NSWindow.willCloseNotification, object: colorPalleteWindow) { [weak self] _ in
            self?.uncheckColorPalleteWindowMenuItem()
        }
        observeNotification(forName: NSWindow.willCloseNotification, object: mainWindow) { [weak self] _ in
            self?.closeOtherWindows()
        }
        observeNotification(forName: NSPopUpButton.willPopUpNotification, object: templatePopupButton) { [weak self] notification in
            self?.constructTemplatePopup(notification)
        }
        observeNotification(forName: NSWindow.didBecomeKeyNotification, object: mainWindow) { [weak self] notification in
            self?.otherWindowsDidBecomeKey(notification)
        }
        observeNotification(forName: NSWindow.didBecomeKeyNotification, object: outputWindow) { [weak self] notification in
            self?.otherWindowsDidBecomeKey(notification)
        }
        observeNotification(forName: NSWindow.didBecomeKeyNotification, object: preambleWindow) { [weak self] notification in
            self?.otherWindowsDidBecomeKey(notification)
        }
        observeNotification(forName: NSWindow.didBecomeKeyNotification, object: preferenceWindow) { [weak self] notification in
            self?.preferenceWindowDidBecomeKey(notification)
        }
        observeNotification(forName: NSWindow.didBecomeKeyNotification, object: colorPalleteWindow) { [weak self] notification in
            self?.colorPalleteWindowDidBecomeKey(notification)
        }

        for textField in [dpiTextField, leftMarginTextField, rightMarginTextField, topMarginTextField, bottomMarginTextField, numberOfCompilationTextField] {
            observeNotification(forName: NSControl.textDidChangeNotification, object: textField) { [weak self] notification in
                self?.refreshRelatedStepperValue(notification)
            }
        }
        observeNotification(forName: NSControl.textDidChangeNotification, object: tabWidthTextField) { [weak self] _ in
            guard let self else { return }
            self.refreshTextView(self.tabWidthTextField)
        }
        observeNotification(forName: NSControl.textDidChangeNotification, object: outputFileTextField) { [weak self] _ in
            self?.outputFilePathChanged(nil)
        }

        outputFileTextField.stringValue = "\(NSHomeDirectory())/Desktop/equation.eps"
        closeColorPanel()
        closeFontPanel()
        lastActiveWindow = mainWindow

        colorPalleteColorWell.color = .red
        colorPalleteColorSet(colorPalleteColorWell)

        autoDetectionTargetMatrix.setCellColor(.textColor)
        spaceCharacterKindMatrix.setCellColor(.textColor)
        fullwidthSpaceCharacterKindMatrix.setCellColor(.textColor)
        returnCharacterKindMatrix.setCellColor(.textColor)
        tabCharacterKindMatrix.setCellColor(.textColor)
        pageBoxMatrix.setCellColor(.textColor)

        let fileManager = FileManager.default
        let bundleID = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
        let plistFile = "\(NSHomeDirectory())/Library/Preferences/\(bundleID).plist"
        var loadLastProfileSuccess = false

        if fileManager.fileExists(atPath: plistFile) {
            profileController.loadProfilesFromPlist()
            loadLastProfileSuccess = adoptProfileDuringLauching()
            profileController.removeProfileForName(autoSavedProfileName)
        }

        if !loadLastProfileSuccess {
            profileController.initProfiles()
            searchProgramsLogic([
                "Title": NSLocalizedString("initSettingsMsg", comment: ""),
                "Msg1": NSLocalizedString("setPathMsg1", comment: ""),
                "Msg2": NSLocalizedString("setPathMsg2", comment: ""),
                "waitUntilDone": false
            ])

            let templateName = autoDetectionTargetMatrix.selectedCell()?.title ?? ""
            if let originalTemplateDirectory = Bundle.main.path(forResource: templateDirectoryName, ofType: nil) {
                let templatePath = originalTemplateDirectory.appendingPathComponent(templateName).appendingPathExtension("tex") ?? ""
                if let data = try? Data(contentsOf: URL(fileURLWithPath: templatePath)) {
                    var detectedEncoding: UInt = 0
                    if let contents = String.stringWithAutoEncodingDetectionOfData(data, detectedEncoding: &detectedEncoding) {
                        preambleTextView.replaceEntireContents(with: contents)
                    }
                }
            }

            loadDefaultFont()
            loadDefaultColorsLogic(senderTag: -1)
            UserDefaults.standard.set(true, forKey: "SUEnableAutomaticChecks")
        }

        let completionPath = "~/Library/TeXShop/CommandCompletion/CommandCompletion.txt".expandingTildeInPath.standardizingPath
        if fileManager.fileExists(atPath: completionPath),
           let completionData = try? Data(contentsOf: URL(fileURLWithPath: completionPath)),
           var completionList = String(data: completionData, encoding: .utf8) {
            if !completionList.hasPrefix("\n") {
                completionList = "\n" + completionList
            }
            if !completionList.hasSuffix("\n") {
                completionList += "\n"
            }
            commandCompletionList = completionList
        }

        if !fileManager.fileExists(atPath: templateDirectoryPath) {
            restoreDefaultTemplatesLogic()
        }

        updateCUIToolStatus()
        preferencesChanged(self)
        outputFilePathChanged(self)
    }

    private func updateCUIToolStatus() {
        if FileManager.default.fileExists(atPath: CUI_PATH) {
            cuiToolInstallButton.title = NSLocalizedString("Uninstall...", comment: "")
            cuiToolStatusView.image = NSImage(named: NSImage.statusAvailableName)
            cuiToolStatusTextField.stringValue = String(format: NSLocalizedString("Installed", comment: ""), CUI_PATH)
        } else {
            cuiToolInstallButton.title = NSLocalizedString("Install...", comment: "")
            cuiToolStatusView.image = NSImage(named: NSImage.statusUnavailableName)
            cuiToolStatusTextField.stringValue = NSLocalizedString("Not Installed", comment: "")
        }
    }

    private func loadDefaultFont() {
        if let defaultFont = NSFont(name: "Osaka-Mono", size: 13) {
            sourceFont = defaultFont
            sourceTextView.font = defaultFont
            preambleTextView.font = defaultFont
            setupFontTextField(defaultFont)
        }
    }

    @IBAction func loadDefaultColors(_ sender: NSButton) {
        loadDefaultColorsLogic(senderTag: sender.tag)
    }

    private func loadDefaultColorsLogic(senderTag: Int) {
        if senderTag == LIGHTMODE_TAG || senderTag == DARKMODE_TAG {
            let modeName = NSLocalizedString(senderTag == LIGHTMODE_TAG ? "Light Mode" : "Dark Mode", comment: "")
            if !UtilityG.runConfirmPanel(message: String(format: NSLocalizedString("restoreColorsConfirmationMsg", comment: ""), modeName)) {
                return
            }
        }

        if senderTag < 0 || senderTag == LIGHTMODE_TAG {
            lightModeForegroundColorWell.color = .defaultForegroundColorForLightMode
            lightModeBackgroundColorWell.color = .defaultBackgroundColorForLightMode
            lightModeCursorColorWell.color = .defaultCursorColorForLightMode
            lightModeBraceColorWell.color = .defaultBraceColorForLightMode
            lightModeCommentColorWell.color = .defaultCommentColorForLightMode
            lightModeCommandColorWell.color = .defaultCommandColorForLightMode
            lightModeInvisibleColorWell.color = .defaultInvisibleColorForLightMode
            lightModeHighlightedBraceColorWell.color = .defaultHighlightedBraceColorForLightMode
            lightModeEnclosedContentBackgroundColorWell.color = .defaultEnclosedContentBackgroundColorForLightMode
            lightModeFlashingBackgroundColorWell.color = .defaultFlashingBackgroundColorForLightMode
            lightModeConsoleForegroundColorWell.color = .defaultConsoleForegroundColorForLightMode
            lightModeConsoleBackgroundColorWell.color = .defaultConsoleBackgroundColorForLightMode
            lightModeForegroundColorWell.saveColor(to: &lastColorDict)
            lightModeBackgroundColorWell.saveColor(to: &lastColorDict)
            lightModeCursorColorWell.saveColor(to: &lastColorDict)
            lightModeBraceColorWell.saveColor(to: &lastColorDict)
            lightModeCommentColorWell.saveColor(to: &lastColorDict)
            lightModeCommandColorWell.saveColor(to: &lastColorDict)
            lightModeInvisibleColorWell.saveColor(to: &lastColorDict)
            lightModeHighlightedBraceColorWell.saveColor(to: &lastColorDict)
            lightModeEnclosedContentBackgroundColorWell.saveColor(to: &lastColorDict)
            lightModeFlashingBackgroundColorWell.saveColor(to: &lastColorDict)
            lightModeConsoleForegroundColorWell.saveColor(to: &lastColorDict)
            lightModeConsoleBackgroundColorWell.saveColor(to: &lastColorDict)
        }

        if senderTag < 0 || senderTag == DARKMODE_TAG {
            darkModeForegroundColorWell.color = .defaultForegroundColorForDarkMode
            darkModeBackgroundColorWell.color = .defaultBackgroundColorForDarkMode
            darkModeCursorColorWell.color = .defaultCursorColorForDarkMode
            darkModeBraceColorWell.color = .defaultBraceColorForDarkMode
            darkModeCommentColorWell.color = .defaultCommentColorForDarkMode
            darkModeCommandColorWell.color = .defaultCommandColorForDarkMode
            darkModeInvisibleColorWell.color = .defaultInvisibleColorForDarkMode
            darkModeHighlightedBraceColorWell.color = .defaultHighlightedBraceColorForDarkMode
            darkModeEnclosedContentBackgroundColorWell.color = .defaultEnclosedContentBackgroundColorForDarkMode
            darkModeFlashingBackgroundColorWell.color = .defaultFlashingBackgroundColorForDarkMode
            darkModeConsoleForegroundColorWell.color = .defaultConsoleForegroundColorForDarkMode
            darkModeConsoleBackgroundColorWell.color = .defaultConsoleBackgroundColorForDarkMode
            darkModeForegroundColorWell.saveColor(to: &lastColorDict)
            darkModeBackgroundColorWell.saveColor(to: &lastColorDict)
            darkModeCursorColorWell.saveColor(to: &lastColorDict)
            darkModeBraceColorWell.saveColor(to: &lastColorDict)
            darkModeCommentColorWell.saveColor(to: &lastColorDict)
            darkModeCommandColorWell.saveColor(to: &lastColorDict)
            darkModeInvisibleColorWell.saveColor(to: &lastColorDict)
            darkModeHighlightedBraceColorWell.saveColor(to: &lastColorDict)
            darkModeEnclosedContentBackgroundColorWell.saveColor(to: &lastColorDict)
            darkModeFlashingBackgroundColorWell.saveColor(to: &lastColorDict)
            darkModeConsoleForegroundColorWell.saveColor(to: &lastColorDict)
            darkModeConsoleBackgroundColorWell.saveColor(to: &lastColorDict)
        }

        makeatletterEnabledCheckBox.state = .on
        sourceTextView.colorizeText()
        preambleTextView.colorizeText()
        recolorOutputView()
    }

    private func setupFontTextField(_ font: NSFont) {
        fontTextField.stringValue = String(format: "%@ - %.1fpt", font.displayName ?? font.fontName, font.pointSize)
    }

    private func presentAutoDetectionResult(_ parameters: [String: Any]) {
        UtilityG.runOkPanel(title: parameters["Title"] as? String ?? "",
                            message: String(format: "%@\n%@\n%@\n%@\n%@",
                                            parameters["Msg1"] as? String ?? "",
                                            parameters[LatexPathKey] as? String ?? "",
                                            parameters[DviDriverPathKey] as? String ?? "",
                                            parameters[GsPathKey] as? String ?? "",
                                            parameters["Msg2"] as? String ?? ""))
    }

    private func applicationWillTerminate() {
        if NSColorPanel.sharedColorPanelExists {
            closeColorPanel()
        }
        if NSFontPanel.sharedFontPanelExists {
            closeFontPanel()
        }
        profileController.updateProfile(currentProfile(), forName: autoSavedProfileName)
        profileController.saveProfiles()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        if let outputDataObserver {
            NotificationCenter.default.removeObserver(outputDataObserver)
        }
    }

    private func closeOtherWindows() {
        outputWindow.close()
        preambleWindow.close()
        preferenceWindow.close()
    }

    private func uncheckOutputWindowMenuItem() {
        outputWindowMenuItem.state = .off
    }

    private func uncheckPreambleWindowMenuItem() {
        preambleWindowMenuItem.state = .off
    }

    private func otherWindowsDidBecomeKey(_ notification: Notification) {
        lastActiveWindow = notification.object as? NSWindow
        closeColorPanel()
    }

    @IBAction func showMainWindow(_ sender: Any) {
        showMainWindow()
    }

    private func readOutputData(_ notification: Notification) {
        guard let outputPipe else { return }
        do {
            var data = outputPipe.fileHandleForReading.availableData
            while !data.isEmpty {
                if let str = String(data: data, encoding: .utf8) {
                    appendOutputAndScroll(str, quiet: false)
                }
                data = outputPipe.fileHandleForReading.availableData
            }
        } catch {
        }
        outputPipe.fileHandleForReading.readInBackgroundAndNotify()
    }

    // MARK: - Import / Export

    private func analyzeContents(_ contents: String) -> [String] {
        var contents = contents
        if currentProfile().boolForKey(ConvertYenMarkKey) {
            contents = contents.replacingYenWithBackslash()
        }

        let pattern = "^(.*?)(?:\\r|\\n|\\r\\n)*(?:\\\\|¥)begin\\{document\\}(?:\\r|\\n|\\r\\n)*(.*)(?:\\\\|¥)end\\{document\\}"
        let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        let range = NSRange(location: 0, length: contents.utf16.count)
        if let match = regex?.firstMatch(in: contents, options: [], range: range) {
            let preamble = contents.substring(with: match.range(at: 1)) + "\n"
            let body = contents.substring(with: match.range(at: 2)).deletingLastReturnCharacters() + "\n"
            return [preamble, body]
        }
        return ["", contents]
    }

    private func placeImportedSource(_ contents: String) {
        let parts = analyzeContents(contents)
        if !parts[0].isEmpty {
            preambleTextView.replaceEntireContents(with: parts[0])
        }
        if !parts[1].isEmpty {
            sourceTextView.replaceEntireContents(with: parts[1])
        }
        sourceSettingChanged(directInputButton)
    }

    private func stringEncoding(from option: String?) -> String.Encoding {
        guard let option else { return .utf8 }
        if option == PTEX_ENCODING_SJIS {
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)))
        }
        if option == PTEX_ENCODING_EUC {
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_JP.rawValue)))
        }
        if option == PTEX_ENCODING_JIS {
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue)))
        }
        return .utf8
    }

    private func extractTeXSourceString(fromAnnotationOf document: PDFDocument?) -> String? {
        guard let document else { return nil }
        guard let page = document.page(at: 0) else {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("doesNotContainSource", comment: ""), document.description))
            return nil
        }
        let annotations = page.annotations
        for annotation in annotations where Utility.isTeX2imgAnnotation(annotation) {
            let contents = annotation.contents?.replacingOccurrences(of: "\r\n", with: "\n") ?? ""
            return contents.substring(from: AnnotationHeader.count)
        }
        return nil
    }

    func importSource(fromFilePathOrPDFDocument input: Any, skipConfirm: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)

        var contents: String?
        var outputFilePath: String?

        if let inputPath = input as? String {
            let extensionLower = inputPath.pathExtension.lowercased()
            if extensionLower == "tex" {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) {
                    var detectedEncoding: UInt = 0
                    contents = String.stringWithAutoEncodingDetectionOfData(data, detectedEncoding: &detectedEncoding)
                }
                lastSavedPath = inputPath
            } else if extensionLower == "pdf" {
                let doc = PDFDocument(filePath: inputPath)
                contents = extractTeXSourceString(fromAnnotationOf: doc)
                if contents == nil {
                    UtilityG.runErrorPanel(message: String(format: NSLocalizedString("doesNotContainSource", comment: ""), inputPath))
                    return false
                }
                outputFilePath = inputPath
            } else {
                let bufferLength = getxattr(inputPath, eaKey, nil, 0, 0, 0)
                if bufferLength < 0 {
                    UtilityG.runErrorPanel(message: String(format: NSLocalizedString("doesNotContainSource", comment: ""), inputPath))
                    return false
                }
                let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength)
                defer { buffer.deallocate() }
                getxattr(inputPath, eaKey, buffer, bufferLength, 0, 0)
                contents = String(bytesNoCopy: buffer, length: bufferLength, encoding: .utf8, freeWhenDone: false)
                outputFilePath = inputPath
            }
        } else if let document = input as? PDFDocument {
            contents = extractTeXSourceString(fromAnnotationOf: document)
            if contents == nil {
                UtilityG.runErrorPanel(message: String(format: NSLocalizedString("doesNotContainSource", comment: ""), document.description))
                return false
            }
        } else {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("doesNotContainSource", comment: ""), String(describing: input)))
            return false
        }

        if let contents {
            if skipConfirm || UtilityG.runConfirmPanel(message: NSLocalizedString("overwriteContentsWarningMsg", comment: "")) {
                placeImportedSource(contents)
                if let outputFilePath {
                    outputFileTextField.stringValue = outputFilePath
                }
            }
        } else {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotReadErrorMsg", comment: ""), String(describing: input)))
            return false
        }
        return true
    }

    @IBAction func importSource(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = importExtensions
        openPanel.beginSheetModal(for: mainWindow) { returnCode in
            if returnCode == .OK, let path = openPanel.url?.path {
                self.importSource(fromFilePathOrPDFDocument: path, skipConfirm: false)
            }
        }
    }

    @IBAction func exportSource(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["tex"]
        savePanel.isExtensionHidden = false
        savePanel.canSelectHiddenExtension = true

        if let lastSavedPath {
            savePanel.nameFieldStringValue = lastSavedPath.lastPathComponent
            savePanel.directoryURL = URL(fileURLWithPath: lastSavedPath.deletingLastPathComponent)
        }

        savePanel.beginSheetModal(for: mainWindow) { returnCode in
            guard returnCode == .OK, let outputPath = savePanel.url?.path else { return }
            self.lastSavedPath = outputPath
            let preamble = self.preambleTextView.textStorage?.string ?? ""
            let body = self.sourceTextView.textStorage?.string ?? ""
            let contents = "\(preamble)\n\\begin{document}\n\(body)\n\\end{document}\n"
            let encoding = self.stringEncoding(from: self.currentProfile().stringForKey(EncodingKey))
            do {
                try contents.write(toFile: outputPath, atomically: true, encoding: encoding)
            } catch {
                UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotWriteErrorMsg", comment: ""), outputPath))
            }
        }
    }

    func textViewDroppedFile(_ file: Any) {
        importSource(fromFilePathOrPDFDocument: file, skipConfirm: false)
    }

    // MARK: - Color palette

    @IBAction func toggleColorPalleteWindow(_ sender: Any) {
        if colorPalleteWindow.isVisible {
            colorPalleteWindow.close()
        } else {
            colorPalleteWindowMenuItem.state = .on
            colorPalleteWindow.makeKeyAndOrderFront(nil)
            colorStyleMatrix.sendAction()
        }
    }

    @IBAction func colorPalleteColorSet(_ sender: Any) {
        guard colorPalleteWindow.isKeyWindow else { return }
        colorPalleteColorWell.saveColor(to: &lastColorDict)
        let color = colorPalleteColorWell.color

        var formatString: String?
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        r = color.redComponent
        g = color.greenComponent
        b = color.blueComponent
        switch colorStyleMatrix.selectedTag() {
        case Int(COLOR_TAG):
            formatString = "\\color[rgb]{%lf,%lf,%lf}"
        case Int(TEXTCOLOR_TAG):
            formatString = "\\textcolor[rgb]{%lf,%lf,%lf}{}"
        case Int(COLORBOX_TAG):
            formatString = "\\colorbox[rgb]{%lf,%lf,%lf}{}"
        case Int(DEFINECOLOR_TAG):
            formatString = "\\definecolor{}{rgb}{%lf,%lf,%lf}"
        default:
            break
        }
        if let formatString {
            colorTextField.stringValue = String(format: formatString, r, g, b)
        }
    }

    @IBAction func insertColorCommand(_ sender: Any) {
        if lastActiveWindow == mainWindow {
            sourceTextView.insertText(withIndicator: colorTextField.stringValue)
        } else if lastActiveWindow == preambleWindow {
            preambleTextView.insertText(withIndicator: colorTextField.stringValue)
        }
    }

    private func uncheckColorPalleteWindowMenuItem() {
        colorPalleteWindowMenuItem.state = .off
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.orderOut(self)
        }
    }

    private func preferenceWindowDidBecomeKey(_ notification: Notification) {
        lastActiveWindow = notification.object as? NSWindow
        fillColorWell.restoreColor(from: lastColorDict)
        lightModeForegroundColorWell.restoreColor(from: lastColorDict)
        lightModeBackgroundColorWell.restoreColor(from: lastColorDict)
        lightModeCursorColorWell.restoreColor(from: lastColorDict)
        lightModeBraceColorWell.restoreColor(from: lastColorDict)
        lightModeCommentColorWell.restoreColor(from: lastColorDict)
        lightModeCommandColorWell.restoreColor(from: lastColorDict)
        lightModeInvisibleColorWell.restoreColor(from: lastColorDict)
        lightModeHighlightedBraceColorWell.restoreColor(from: lastColorDict)
        lightModeEnclosedContentBackgroundColorWell.restoreColor(from: lastColorDict)
        lightModeFlashingBackgroundColorWell.restoreColor(from: lastColorDict)
    }

    private func colorPalleteWindowDidBecomeKey(_ notification: Notification) {
        colorPalleteColorWell.restoreColor(from: lastColorDict)
    }

    private func closeColorPanel() {
        fillColorWell.deactivate()
        lightModeForegroundColorWell.deactivate()
        lightModeBackgroundColorWell.deactivate()
        lightModeCursorColorWell.deactivate()
        lightModeBraceColorWell.deactivate()
        lightModeCommentColorWell.deactivate()
        lightModeCommandColorWell.deactivate()
        lightModeInvisibleColorWell.deactivate()
        lightModeHighlightedBraceColorWell.deactivate()
        lightModeEnclosedContentBackgroundColorWell.deactivate()
        lightModeFlashingBackgroundColorWell.deactivate()
        lightModeConsoleForegroundColorWell.deactivate()
        lightModeConsoleBackgroundColorWell.deactivate()
        darkModeForegroundColorWell.deactivate()
        darkModeBackgroundColorWell.deactivate()
        darkModeCursorColorWell.deactivate()
        darkModeBraceColorWell.deactivate()
        darkModeCommentColorWell.deactivate()
        darkModeCommandColorWell.deactivate()
        darkModeInvisibleColorWell.deactivate()
        darkModeHighlightedBraceColorWell.deactivate()
        darkModeEnclosedContentBackgroundColorWell.deactivate()
        darkModeFlashingBackgroundColorWell.deactivate()
        darkModeConsoleForegroundColorWell.deactivate()
        darkModeConsoleBackgroundColorWell.deactivate()
        colorPalleteColorWell.deactivate()
        NSColorPanel.shared.perform(#selector(NSColorPanel.orderOut(_:)), with: self, afterDelay: 0)
        fillColorWell.restoreColor(from: lastColorDict)
        lightModeForegroundColorWell.restoreColor(from: lastColorDict)
        lightModeBackgroundColorWell.restoreColor(from: lastColorDict)
        lightModeCursorColorWell.restoreColor(from: lastColorDict)
        lightModeBraceColorWell.restoreColor(from: lastColorDict)
        lightModeCommentColorWell.restoreColor(from: lastColorDict)
        lightModeCommandColorWell.restoreColor(from: lastColorDict)
        lightModeInvisibleColorWell.restoreColor(from: lastColorDict)
        lightModeHighlightedBraceColorWell.restoreColor(from: lastColorDict)
        lightModeEnclosedContentBackgroundColorWell.restoreColor(from: lastColorDict)
        lightModeFlashingBackgroundColorWell.restoreColor(from: lastColorDict)
        lightModeConsoleForegroundColorWell.restoreColor(from: lastColorDict)
        lightModeConsoleBackgroundColorWell.restoreColor(from: lastColorDict)
        darkModeForegroundColorWell.restoreColor(from: lastColorDict)
        darkModeBackgroundColorWell.restoreColor(from: lastColorDict)
        darkModeCursorColorWell.restoreColor(from: lastColorDict)
        darkModeBraceColorWell.restoreColor(from: lastColorDict)
        darkModeCommentColorWell.restoreColor(from: lastColorDict)
        darkModeCommandColorWell.restoreColor(from: lastColorDict)
        darkModeInvisibleColorWell.restoreColor(from: lastColorDict)
        darkModeHighlightedBraceColorWell.restoreColor(from: lastColorDict)
        darkModeEnclosedContentBackgroundColorWell.restoreColor(from: lastColorDict)
        darkModeFlashingBackgroundColorWell.restoreColor(from: lastColorDict)
        darkModeConsoleForegroundColorWell.restoreColor(from: lastColorDict)
        darkModeConsoleBackgroundColorWell.restoreColor(from: lastColorDict)
        colorPalleteColorWell.restoreColor(from: lastColorDict)
    }

    private func closeFontPanel() {
        NSFontPanel.shared.perform(#selector(NSFontPanel.orderOut(_:)), with: self, afterDelay: 0)
    }

    @IBAction private func dialogOk(_ sender: Any) {
        NSApp.stopModal(withCode: .OK)
    }

    @IBAction private func dialogCancel(_ sender: Any) {
        NSApp.stopModal(withCode: .cancel)
    }

    @IBAction func saveAsTemplate(_ sender: Any) {
        let dialogSize = NSSize(width: 340, height: 120)
        let dialog = NSWindow(contentRect: NSRect(origin: .zero, size: dialogSize),
                              styleMask: [.titled, .resizable],
                              backing: .buffered,
                              defer: false)
        dialog.setFrame(NSRect(origin: .zero, size: dialogSize), display: false)
        dialog.minSize = NSSize(width: 250, height: dialogSize.height)
        dialog.maxSize = NSSize(width: 10000, height: dialogSize.height)
        dialog.title = NSLocalizedString("saveCurrentPreambleAsTemplate", comment: "")

        let input = NSTextField(frame: NSRect(x: 17, y: 54, width: dialogSize.width - 40, height: 25))
        input.autoresizingMask = .width
        dialog.contentView?.addSubview(input)
        if let title = sender as? String {
            input.stringValue = title
        }

        let cancelButton = NSButton(frame: NSRect(x: dialogSize.width - 206, y: 12, width: 96, height: 32))
        cancelButton.title = NSLocalizedString("Cancel", comment: "")
        cancelButton.bezelStyle = .rounded
        cancelButton.autoresizingMask = .minXMargin
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.target = self
        cancelButton.action = #selector(dialogCancel(_:))
        dialog.contentView?.addSubview(cancelButton)

        let okButton = NSButton(frame: NSRect(x: dialogSize.width - 110, y: 12, width: 96, height: 32))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.autoresizingMask = .minXMargin
        okButton.keyEquivalent = "\r"
        okButton.target = self
        okButton.action = #selector(dialogOk(_:))
        dialog.contentView?.addSubview(okButton)

        let returnCode = NSApp.runModal(for: dialog)
        dialog.orderOut(self)

        guard returnCode == .OK else { return }
        let title = input.stringValue
        if title.isEmpty {
            saveAsTemplate(title)
            return
        }

        let filePath = templateDirectoryPath.appendingPathComponent(title.appendingPathExtension("tex") ?? title)
        if FileManager.default.fileExists(atPath: filePath),
           !UtilityG.runConfirmPanel(message: NSLocalizedString("profileOverwriteMsg", comment: "")) {
            saveAsTemplate(title)
            return
        }

        let preamble = preambleTextView.textStorage?.string ?? ""
        do {
            try preamble.write(toFile: filePath, atomically: false, encoding: .utf8)
        } catch {
            UtilityG.runErrorPanel(message: String(format: NSLocalizedString("cannotWriteErrorMsg", comment: ""), filePath))
        }
    }

    @IBAction func openTemplateDirectory(_ sender: Any) {
        NSWorkspace.shared.openFile(templateDirectoryPath, withApplication: "Finder")
    }

    @IBAction func openTempDir(_ sender: Any) {
        NSWorkspace.shared.openFile(FileManager.default.temporaryDirectory.path, withApplication: "Finder")
    }

    @IBAction func showPreferenceWindow(_ sender: Any) {
        preferenceWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func showProfilesWindow(_ sender: Any) {
        profileController.showProfileWindow()
    }

    @IBAction func sourceSettingChanged(_ sender: Any) {
        switch (sender as? NSView)?.tag {
        case Int(DIRECT_INPUT_TAG):
            directInputButton.state = .on
            inputSourceFileButton.state = .off
            sourceTextView.setEnabled(true as Bool)
            mainWindow.endEditing(for: inputSourceFileTextField)
            inputSourceFileTextField.isEnabled = false
            browseSourceFileButton.isEnabled = false
        case Int(INPUT_FILE_TAG):
            directInputButton.state = .off
            inputSourceFileButton.state = .on
            sourceTextView.setEnabled(false as Bool)
            inputSourceFileTextField.isEnabled = true
            browseSourceFileButton.isEnabled = true
        default:
            break
        }
    }

    @IBAction func showInputSourceFilePanel(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = inputExtensions
        openPanel.beginSheetModal(for: mainWindow) { returnCode in
            if returnCode == .OK {
                self.inputSourceFileTextField.stringValue = openPanel.url?.path ?? ""
            }
        }
    }

    @IBAction func showSavePanel(_ sender: Any) {
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 270, height: 50))
        let popUpButton = NSPopUpButton(frame: NSRect(x: 130, y: 10, width: 120, height: 25))
        let titles = targetExtensions.map { $0.uppercased() }
        popUpButton.addItems(withTitles: titles)

        let label = NSTextField(frame: NSRect(x: 20, y: 15, width: 100, height: 18))
        label.stringValue = NSLocalizedString("Format", comment: "")
        label.alignment = .right
        label.isBordered = false
        label.isSelectable = false
        label.isEditable = false
        label.backgroundColor = .clear
        accessoryView.addSubview(popUpButton)
        accessoryView.addSubview(label)

        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = targetExtensions
        savePanel.isExtensionHidden = false
        savePanel.canSelectHiddenExtension = false
        savePanel.accessoryView = accessoryView
        popUpButton.action = #selector(extensionPopUpButtonInSavePanelChanged(_:))
        popUpButton.target = self

        let defaultFilePath = outputFileTextField.stringValue
        let defaultExtensionUpper = extensionPopupButton.selectedItem?.title ?? "EPS"
        let defaultExtensionLower = defaultExtensionUpper.lowercased()
        savePanel.nameFieldStringValue = defaultFilePath.lastPathComponent.deletingPathExtension + ".\(defaultExtensionLower)"
        popUpButton.selectItem(withTitle: defaultExtensionUpper)
        savePanel.directoryURL = URL(fileURLWithPath: defaultFilePath.deletingLastPathComponent)

        savePanel.beginSheetModal(for: mainWindow) { returnCode in
            if returnCode == .OK, let path = savePanel.url?.path {
                self.outputFileTextField.stringValue = path
                self.outputFilePathChanged(nil)
            }
        }
    }

    @IBAction private func extensionPopUpButtonInSavePanelChanged(_ sender: NSPopUpButton) {
        guard let savePanel = sender.window as? NSSavePanel else { return }
        let oldName = savePanel.nameFieldStringValue
        let extensionLower = sender.selectedItem?.title.lowercased() ?? ""
        savePanel.nameFieldStringValue = oldName.deletingPathExtension.appendingPathExtension(extensionLower) ?? oldName
        savePanel.allowedFileTypes = [extensionLower] + (savePanel.allowedFileTypes ?? [])
    }

    @IBAction func toggleMenuItem(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem else { return }
        menuItem.state = menuItem.state == .on ? .off : .on
        refreshTextView(sender)
    }

    @IBAction func refreshTextView(_ sender: Any) {
        tabWidthStepper.integerValue = tabWidthTextField.integerValue
        sourceTextView.refreshWordWrap()
        sourceTextView.colorizeText()
        sourceTextView.fixupTabs()
        preambleTextView.refreshWordWrap()
        preambleTextView.colorizeText()
        preambleTextView.fixupTabs()
    }

    @IBAction func tabWidthStepperPressed(_ sender: Any) {
        tabWidthTextField.integerValue = tabWidthStepper.integerValue
        refreshTextView(sender)
    }

    private func refreshRelatedStepperValue(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField,
              let stepper = textField.target as? NSStepper else { return }
        stepper.integerValue = textField.integerValue
    }

    @IBAction func toggleOutputWindow(_ sender: Any) {
        if outputWindow.isVisible {
            outputWindow.close()
        } else {
            showOutputWindow()
        }
    }

    @IBAction func togglePreambleWindow(_ sender: Any) {
        if mainWindow.isInFullScreenMode {
            preambleWindow.makeKeyAndOrderFront(nil)
            preambleTextView.colorizeText()
            return
        }

        if preambleWindow.isVisible {
            preambleWindow.close()
        } else {
            preambleWindowMenuItem.state = .on
            let preambleWindowRect = preambleWindow.frame
            let screen = mainWindow.screen ?? NSScreen.main!
            let preambleWindowNewOriginY = max(mainWindow.frame.minY, screen.visibleFrame.minY)
            let preambleWindowNewHeight = max(mainWindow.frame.maxY - preambleWindowNewOriginY, preambleWindow.minSize.height)

            var newRect = NSRect(x: mainWindow.frame.minX - preambleWindowRect.width,
                                 y: preambleWindowNewOriginY,
                                 width: preambleWindowRect.width,
                                 height: preambleWindowNewHeight)

            if screen.visibleFrame.minX <= newRect.minX {
                preambleWindow.setFrame(newRect, display: false)
            } else {
                newRect = NSRect(x: mainWindow.frame.maxX,
                                 y: preambleWindowNewOriginY,
                                 width: preambleWindowRect.width,
                                 height: preambleWindowNewHeight)
                if newRect.maxX <= screen.visibleFrame.maxX {
                    preambleWindow.setFrame(newRect, display: false)
                } else {
                    let newWidth = max(mainWindow.frame.maxX - screen.visibleFrame.minX - preambleWindow.frame.width - 1, mainWindow.minSize.width)
                    let newX = mainWindow.frame.maxX - newWidth
                    mainWindow.setFrame(NSRect(x: newX, y: mainWindow.frame.origin.y, width: newWidth, height: mainWindow.frame.height), display: true, animate: true)
                    newRect = NSRect(x: screen.visibleFrame.minX,
                                     y: preambleWindowNewOriginY,
                                     width: mainWindow.frame.minX - screen.visibleFrame.minX,
                                     height: preambleWindowNewHeight)
                    preambleWindow.setFrame(newRect, display: false)
                }
            }
            preambleWindow.makeKeyAndOrderFront(nil)
            preambleTextView.colorizeText()
        }
    }

    @IBAction func closeWindow(_ sender: Any) {
        NSApp.keyWindow?.close()
    }

    @IBAction func preferencesChanged(_ sender: Any) {
        keepPageSizeAdvancedButton.isEnabled = keepPageSizeCheckBox.state == .on
        mergeOutputAdvancedButton.isEnabled = mergeOutputsCheckBox.state == .on
        if toClipboardCheckBox.state == .on {
            autoPasteCheckBox.isEnabled = true
            autoPasteDestinationPopUpButton.isEnabled = autoPasteCheckBox.state == .on
        } else {
            autoPasteCheckBox.isEnabled = false
            autoPasteDestinationPopUpButton.isEnabled = false
        }
        ungroupCheckBox.isEnabled = embedInIllustratorCheckBox.state == .on
    }

    @IBAction func showFontPanelOfSource(_ sender: Any) {
        let fontMgr = NSFontManager.shared
        fontMgr.target = self
        fontMgr.action = #selector(changeFont(_:))
        guard let panel = fontMgr.fontPanel(true) else { return }
        if let sourceFont {
            panel.setPanelFont(sourceFont, isMultiple: false)
        }
        panel.makeKeyAndOrderFront(self)
        panel.isEnabled = true
    }

    @IBAction private func changeFont(_ sender: Any) {
        guard let font = NSFontManager.shared.selectedFont else { return }
        setupFontTextField(font)
        sourceFont = font
        sourceTextView.font = font
        preambleTextView.font = font
        outputTextView.font = font
        if let displayFont = NSFont(name: font.fontName, size: spaceCharacterKindButton.font?.pointSize ?? font.pointSize) {
            setInvisibleCharacterFont(displayFont)
        }
    }

    @IBAction func colorSettingChanged(_ sender: Any) {
        guard preferenceWindow.isKeyWindow, let well = sender as? NSColorWell else { return }
        well.saveColor(to: &lastColorDict)
        sourceTextView.refreshSelectionHighlighting()
        preambleTextView.refreshSelectionHighlighting()
        recolorOutputView()
    }

    private func recolorOutputView() {
        let profile = currentProfile()
        refreshTextView(outputTextView,
                        foregroundColor: UtilityG.consoleForegroundColor(inProfile: profile),
                        backgroundColor: UtilityG.consoleBackgroundColor(inProfile: profile),
                        cursorColor: UtilityG.cursorColor(inProfile: profile))
        outputTextView.font = sourceFont
    }

    func searchProgramsLogic(_ parameters: [String: Any]) {
        let templateName = autoDetectionTargetMatrix.selectedCell()?.title ?? ""
        let engineName = templateName.lowercased().components(separatedBy: " ").first ?? ""
        let dviDriverName = templateName.range(of: "dvips") == nil ? "dvipdfmx" : "dvips"

        var latexPath = searchProgram(engineName) ?? ""
        if latexPath.isEmpty { showNotFoundError(engineName) }

        var dviDriverPath = searchProgram(dviDriverName) ?? ""
        if dviDriverPath.isEmpty {
            showNotFoundError(dviDriverName)
        } else if dviDriverName == "dvipdfmx" {
            dviDriverPath += " -vv"
        } else if dviDriverName == "dvips" {
            dviDriverPath += " -Ppdf"
        }

        var gsPath = searchProgram("gs") ?? ""
        if gsPath.isEmpty { showNotFoundError("Ghostscript") }

        latexPathTextField.stringValue = latexPath
        dviDriverPathTextField.stringValue = dviDriverPath
        gsPathTextField.stringValue = gsPath

        let result: [String: Any] = [
            "Title": parameters["Title"] as? String ?? "",
            "Msg1": parameters["Msg1"] as? String ?? "",
            "Msg2": parameters["Msg2"] as? String ?? "",
            LatexPathKey: latexPath.isEmpty ? "LaTeX: Not Found" : latexPath,
            DviDriverPathKey: dviDriverPath.isEmpty ? "DVI Driver: Not Found" : dviDriverPath,
            GsPathKey: gsPath.isEmpty ? "Ghostscript: Not Found" : gsPath
        ]
        let waitUntilDone = (parameters["waitUntilDone"] as? Bool) ?? true
        performOnMainThread(waitUntilDone: waitUntilDone) {
            self.presentAutoDetectionResult(result)
        }
    }

    @IBAction func searchPrograms(_ sender: Any) {
        searchProgramsLogic([
            "Title": NSLocalizedString("autoDetectionResult", comment: ""),
            "Msg1": NSLocalizedString("setPathMsg1", comment: ""),
            "Msg2": NSLocalizedString("setPathMsg3", comment: ""),
            "waitUntilDone": true
        ])

        let templateName = autoDetectionTargetMatrix.selectedCell()?.title ?? ""
        if let originalTemplateDirectory = Bundle.main.path(forResource: templateDirectoryName, ofType: nil) {
            let templatePath = originalTemplateDirectory.appendingPathComponent(templateName).appendingPathExtension("tex") ?? ""
            adoptPreambleTemplate(templatePath)
        }
    }

    private func completeGenerationDidFinish(_ status: ExitStatus) {
        converter?.deleteTemporaryFiles()
        generateButton.title = NSLocalizedString("Generate", comment: "")
        generateButton.action = #selector(generate(_:))
        generateMenuItem.isEnabled = true
        abortMenuItem.isEnabled = false
        taskKilled = false

        if currentProfile().boolForKey(SendNotificationKey) {
            sendUserNotification(status: status)
        }
    }

    func generationDidFinish(_ status: ExitStatus) {
        performOnMainThread {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.completeGenerationDidFinish(status)
            }
        }
    }

    private func printCurrentStatus(_ profile: Profile) {
        var output = ""
        output += "************************************\n  TeX2img settings\n************************************\n"
        output += "Version: \(profile.stringForKey(TeX2imgVersionKey) ?? "")\n"
        let outputFilePath = profile.stringForKey(OutputFileKey) ?? ""
        output += "Output file: \(outputFilePath)\n"
        let encoding = profile.stringForKey(EncodingKey) ?? ""
        let kanji = encoding == PTEX_ENCODING_NONE ? "" : " -kanji=\(encoding)"
        output += "LaTeX compiler: \(profile.stringForKey(LatexPathKey) ?? "") \(kanji)\n"
        output += "Auto detection of the number of compilation: "
        if profile.boolForKey(GuessCompilationKey) {
            output += "enabled\nThe maximal number of compilation: \(profile.integerForKey(NumberOfCompilationKey))\n"
        } else {
            output += "disabled\nThe number of compilation: \(profile.integerForKey(NumberOfCompilationKey))\n"
        }
        output += "DVI Driver: \(profile.stringForKey(DviDriverPathKey) ?? "")\n"
        output += "Ghostscript: \(profile.stringForKey(GsPathKey) ?? "")\nWorking directory: "
        if profile.integerForKey(WorkingDirectoryTypeKey) == WorkingDirectoryFile && profile.integerForKey(InputMethodKey) == InputMethod.fromFile.rawValue {
            output += profile.stringForKey(InputSourceFilePathKey)?.deletingLastPathComponent ?? ""
        } else {
            output += FileManager.default.temporaryDirectory.path
        }
        output += "\nResolution level: \(profile.floatForKey(ResolutionKey))\n"
        output += "DPI: \(profile.integerForKey(DPIKey))\n"
        let ext = outputFilePath.pathExtension
        let unit = profile.integerForKey(UnitKey) == PX_UNIT_TAG && ["png", "gif", "tiff"].contains(ext) ? "px" : "bp"
        output += "Left   margin: \(profile.integerForKey(LeftMarginKey))\(unit)\n"
        output += "Right  margin: \(profile.integerForKey(RightMarginKey))\(unit)\n"
        output += "Top    margin: \(profile.integerForKey(TopMarginKey))\(unit)\n"
        output += "Bottom margin: \(profile.integerForKey(BottomMarginKey))\(unit)\n"
        output += "Transparent: \(profile.boolForKey(TransparentKey) ? enabledLabel : disabledLabel)\n"
        output += "Background color: \(profile.colorForKey(FillColorKey)?.descriptionString ?? "")\n"
        if ext == "pdf" {
            output += "Text embedded PDF: \(profile.boolForKey(GetOutlineKey) ? disabledLabel : enabledLabel)\n"
        }
        if ext == "eps" {
            output += "Plain text EPS: \(profile.boolForKey(PlainTextKey) ? enabledLabel : disabledLabel)\n"
        }
        if ext == "svg" || ext == "svgz" {
            output += "Delete width and height attributes of SVG: \(profile.boolForKey(DeleteDisplaySizeKey) ? enabledLabel : disabledLabel)\n"
        }
        output += "Ignore nonfatal errors: \(profile.boolForKey(IgnoreErrorKey) ? enabledLabel : disabledLabel)\n"
        output += "Substitute \\UTF / \\CID for non-JIS X 0208 characters: \(profile.boolForKey(UtfExportKey) ? enabledLabel : disabledLabel)\n"
        output += "Conversion mode: \(profile.integerForKey(PriorityKey) == SPEED_PRIORITY_TAG ? "speed" : "quality") priority mode\n"
        output += "Send notification: \(profile.boolForKey(SendNotificationKey) ? enabledLabel : disabledLabel)\n"
        output += "Preview generated files: \(profile.boolForKey(PreviewKey) ? enabledLabel : disabledLabel)\n"
        output += "Delete temporary files: \(profile.boolForKey(DeleteTmpFileKey) ? enabledLabel : disabledLabel)\n"
        output += "Embed source into generated files: \(profile.boolForKey(EmbedSourceKey) ? enabledLabel : disabledLabel)\n"
        output += "Copy generated files to clipboard: \(profile.boolForKey(CopyToClipboardKey) ? enabledLabel : disabledLabel)\n"
        output += "Paste generated files into \(autoPasteDestinationPopUpButton.selectedItem?.title ?? ""): \(profile.boolForKey(AutoPasteKey) ? enabledLabel : disabledLabel)\n"
        if profile.boolForKey(EmbedInIllustratorKey) {
            output += "Embed generated files in Illustrator: enabled\nUngroup after embedding: \(profile.boolForKey(UngroupKey) ? enabledLabel : disabledLabel)\n"
        } else {
            output += "Embed generated files in Illustrator: disabled\n"
        }
        output += "************************************\n\n"
        appendOutputAndScroll(output, quiet: false)
    }

    private func generateImage() {
        let profile = currentProfile()
        profile[EpstopdfPathKey] = Bundle.main.path(forResource: "epstopdf", ofType: nil)
        if let mupdfPath = Bundle.main.path(forResource: "mupdf", ofType: nil) {
            profile[MudrawPathKey] = mupdfPath.appendingPathComponent("mudraw")
        }
        if let pdftopsBase = Bundle.main.path(forResource: "pdftops", ofType: nil) {
            profile[PdftopsPathKey] = pdftopsBase.appendingPathComponent("pdftops")
        }
        profile[QuietKey] = false
        profile[ControllerKey] = self

        converter = Converter.converter(withProfile: profile)
        outputTextView.textStorage?.mutableString.setString("")
        printCurrentStatus(profile)

        switch InputMethod(rawValue: profile.integerForKey(InputMethodKey)) ?? .direct {
        case .direct:
            let body = sourceTextView.textStorage?.string ?? ""
            DispatchQueue.global(qos: .userInitiated).async { [converter] in
                converter?.compileAndConvert(withBody: body)
            }
        case .fromFile:
            let inputSourceFilePath = profile.stringForKey(InputSourceFilePathKey)?.standardizingPath ?? ""
            if FileManager.default.fileExists(atPath: inputSourceFilePath) {
                let ext = inputSourceFilePath.pathExtension
                if inputExtensions.contains(ext) {
                    DispatchQueue.global(qos: .userInitiated).async { [converter] in
                        converter?.compileAndConvert(withInputPath: inputSourceFilePath)
                    }
                } else {
                    UtilityG.runErrorPanel(message: String(format: NSLocalizedString("inputFileTypeErrorMsg", comment: ""), inputSourceFilePath))
                    generationDidFinish(.failed)
                }
            } else {
                UtilityG.runErrorPanel(message: String(format: NSLocalizedString("inputFileNotFoundErrorMsg", comment: ""), inputSourceFilePath))
                generationDidFinish(.failed)
            }
        }
    }

    @IBAction func generate(_ sender: Any) {
        var valid = true
        let fields: [NSTextField] = [leftMarginTextField, rightMarginTextField, topMarginTextField, bottomMarginTextField, resolutionTextField, dpiTextField, numberOfCompilationTextField, tabWidthTextField]
        for label in fields {
            guard let formatter = label.formatter as? NumberFormatter,
                  let value = formatter.number(from: label.stringValue) else {
                UtilityG.runErrorPanel(message: String(format: NSLocalizedString("formatErrorMsg", comment: ""), label.toolTip ?? ""))
                valid = false
                continue
            }
            let actionName = label.action.map { NSStringFromSelector($0) } ?? ""
            if actionName == "takeIntValueFrom:" {
                label.integerValue = value.intValue
            } else if actionName == "takeFloatValueFrom:" {
                label.floatValue = value.floatValue
            }
            if let action = label.action, let target = label.target {
                NSApp.sendAction(action, to: target, from: label)
            }
        }
        guard valid else { return }

        mainWindow.makeKey()
        if showOutputWindowCheckBox.state == .on {
            showOutputWindow()
        }
        generateButton.title = NSLocalizedString("Abort", comment: "")
        generateButton.action = #selector(abortCompilation(_:))
        generateMenuItem.isEnabled = false
        abortMenuItem.isEnabled = true
        generateImage()
    }

    @IBAction func abortCompilation(_ sender: Any) {
        taskKilled = true
        if let runningTask, runningTask.isRunning {
            runningTask.terminate()
            self.runningTask = nil
            generationDidFinish(.aborted)
        }
    }

    @IBAction func showAutoDetectionTargetSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: autoDetectionTargetSettingViewController, atRightOf: sender, view: preferenceWindow.contentView!, offsetX: 25, y: 24)
    }

    @IBAction func showPageBoxSettingPopover(_ sender: NSButton) {
        let y = preferenceWindow.frame.size.height - (UtilityG.isJapaneseLanguage() ? 313 : 300)
        NSPopover.show(with: pageBoxSettingViewController, atRightOf: sender, view: preferenceWindow.contentView!, offsetX: 32, y: y)
    }

    @IBAction func showAnimationParameterSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: animationParameterSettingViewController, atRightOf: sender, view: preferenceWindow.contentView!, offsetX: 32, y: preferenceWindow.frame.size.height - 446)
    }

    @IBAction func extensionPopUpButtonChanged(_ sender: NSPopUpButton) {
        let ext = sender.selectedItem?.title.lowercased() ?? ""
        outputFileTextField.stringValue = outputFileTextField.stringValue.deletingPathExtension.appendingPathExtension(ext) ?? outputFileTextField.stringValue
    }

    @IBAction func outputFilePathChanged(_ sender: Any?) {
        let newExtension = outputFileTextField.stringValue.lastPathComponent.pathExtension
        if targetExtensions.contains(newExtension) {
            extensionPopupButton.selectItem(withTitle: newExtension.uppercased())
        }
    }

    @IBAction func openSystemPreferencePane(_ sender: Any) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func installCUITool(_ sender: Any) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: CUI_PATH) {
            let message = String(format: NSLocalizedString("Uninstall CUI Confirmation", comment: ""), CUI_PATH)
            if UtilityG.runConfirmPanel(message: message) {
                do {
                    try fileManager.removeItem(atPath: CUI_PATH)
                } catch {
                    var output: NSString?
                    var errorMessage: NSString?
                    _ = sudoCommand("/bin/rm", atDirectory: FileManager.default.temporaryDirectory.path, withArguments: [CUI_PATH], stdoutString: &output, errorDescription: &errorMessage)
                    if let errorMessage {
                        UtilityG.runErrorPanel(message: errorMessage as String)
                    }
                }
            }
        } else {
            let message = String(format: NSLocalizedString("Install CUI Confirmation", comment: ""), CUI_PATH)
            if UtilityG.runConfirmPanel(message: message) {
                let cuiInAppPath = Bundle.main.sharedSupportPath.map {
                    $0.appendingPathComponent("bin").appendingPathComponent("tex2img")
                } ?? ""
                do {
                    try fileManager.createSymbolicLink(atPath: CUI_PATH, withDestinationPath: cuiInAppPath)
                } catch {
                    let cuiDir = CUI_PATH.deletingLastPathComponent
                    var output: NSString?
                    var errorMessage: NSString?
                    _ = sudoCommand("/bin/mkdir", atDirectory: FileManager.default.temporaryDirectory.path, withArguments: ["-p", cuiDir], stdoutString: &output, errorDescription: &errorMessage)
                    if errorMessage == nil {
                        _ = sudoCommand("/bin/ln", atDirectory: FileManager.default.temporaryDirectory.path, withArguments: ["-sf", cuiInAppPath, CUI_PATH], stdoutString: &output, errorDescription: &errorMessage)
                    }
                    if let errorMessage {
                        UtilityG.runErrorPanel(message: errorMessage as String)
                    }
                }
            }
        }
        updateCUIToolStatus()
    }

    @IBAction func showSpaceCharacterKindSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: spaceCharacterKindSettingViewController, atRightOf: sender, view: invisibleCharacterBox, offsetX: 2, y: 1)
    }

    @IBAction func showFullwidthSpaceCharacterKindSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: fullwidthSpaceCharacterKindSettingViewController, atRightOf: sender, view: invisibleCharacterBox, offsetX: 2, y: 1)
    }

    @IBAction func showReturnCharacterKindSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: returnCharacterKindSettingViewController, atRightOf: sender, view: invisibleCharacterBox, offsetX: 2, y: 1)
    }

    @IBAction func showTabCharacterKindSettingPopover(_ sender: NSButton) {
        NSPopover.show(with: tabCharacterKindSettingViewController, atRightOf: sender, view: invisibleCharacterBox, offsetX: 2, y: 1)
    }

    @IBAction func invisibleCharacterKindChanged(_ sender: Any?) {
        spaceCharacterKindButton.title = spaceCharacter()
        fullwidthSpaceCharacterKindButton.title = fullwidthSpaceCharacter()
        returnCharacterKindButton.title = returnCharacter()
        tabCharacterKindButton.title = tabCharacter()
        sourceTextView.colorizeText()
        preambleTextView.colorizeText()
    }

    func spaceCharacter() -> String {
        (spaceCharacterKindMatrix.selectedCell() as? NSButton)?.title ?? ""
    }

    func fullwidthSpaceCharacter() -> String {
        (fullwidthSpaceCharacterKindMatrix.selectedCell() as? NSButton)?.title ?? ""
    }

    func returnCharacter() -> String {
        (returnCharacterKindMatrix.selectedCell() as? NSButton)?.title ?? ""
    }

    func tabCharacter() -> String {
        (tabCharacterKindMatrix.selectedCell() as? NSButton)?.title ?? ""
    }

    func showTabCharacterEnabled() -> Bool {
        currentProfile().boolForKey(ShowTabCharacterKey)
    }

    func showNewLineCharacterEnabled() -> Bool {
        currentProfile().boolForKey(ShowNewLineCharacterKey)
    }

    func showFullwidthSpaceCharacterEnabled() -> Bool {
        currentProfile().boolForKey(ShowFullwidthSpaceCharacterKey)
    }

    func showSpaceCharacterEnabled() -> Bool {
        currentProfile().boolForKey(ShowSpaceCharacterKey)
    }

    func invisibleColor() -> NSColor {
        UtilityG.invisibleColor(inProfile: currentProfile())
    }
}