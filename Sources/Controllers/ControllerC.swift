import Foundation

@objc(ControllerC)
class ControllerC: NSObject, OutputController {
    @objc func execCommand(_ command: String,
                           atDirectory path: String,
                           withArguments arguments: [String],
                           quiet: Bool) -> Bool {
        FileManager.default.changeCurrentDirectoryPath(path)

        let displayCommand = ([command] + arguments).joined(separator: " ") + " 2>&1"
        appendOutputAndScroll(String(format: "$ %@\n", displayCommand), quiet: quiet)

        let task = Process()
        let pipe = Pipe()
        task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
        task.currentDirectoryURL = URL(fileURLWithPath: path)
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardError = pipe

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] source in
            let data = source.availableData
            if data.isEmpty {
                source.readabilityHandler = nil
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                self?.appendOutputAndScroll(str, quiet: quiet)
            }
        }

        do {
            try task.run()
        } catch {
            return false
        }

        task.waitUntilExit()
        handle.readabilityHandler = nil
        return task.terminationStatus == 0
    }

    @objc func prepareOutputTextView() {
    }

    @objc func releaseOutputTextView() {
    }

    @objc func showOutputWindow() {
    }

    @objc func showMainWindow() {
    }

    @objc func latexExists(atPath latexPath: String,
                           dviDriverPath: String,
                           gsPath: String) -> Bool {
        if !UtilityC.checkWhich(latexPath) {
            showNotFoundError(latexPath.programName)
            UtilityC.suggestLatexOption()
            return false
        }
        if !UtilityC.checkWhich(dviDriverPath) {
            showNotFoundError(dviDriverPath.programName)
            return false
        }
        if !UtilityC.checkWhich(gsPath) {
            showNotFoundError(gsPath.programName)
            return false
        }
        return true
    }

    @objc func epstopdfExists() -> Bool {
        if !UtilityC.checkWhich("epstopdf") {
            showNotFoundError("epstopdf")
            return false
        }
        return true
    }

    @objc func mudrawExists() -> Bool {
        if !UtilityC.checkWhich("mudraw") {
            showNotFoundError("mudraw")
            return false
        }
        return true
    }

    @objc func pdftopsExists() -> Bool {
        if !UtilityC.checkWhich("xpdf-pdftops") && !UtilityC.checkWhich("pdftops") {
            showNotFoundError("pdftops")
            UtilityC.printStdErr("tex2img: [Error] Place GUI app (TeX2img.app) in /Applications.\n")
            return false
        }
        return true
    }

    @objc func showNotFoundError(_ aPath: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] Command \"%@\" cannot be found.\nCheck the environment variable $PATH.\n", aPath))
    }

    @objc func showExtensionError() {
        UtilityC.printStdErr("tex2img: [Error] The extention of output file must be either eps/pdf/jpg/png/gif/tiff/bmp/svg.\n")
    }

    @objc func showFileFormatError(_ aPath: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] Invalid file format: %@\n", aPath))
    }

    @objc func showFileGenerationError(_ aPath: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] %@ cannot be created, and so generation has been aborted.\nCheck permission.\n", aPath))
    }

    @objc func showExecError(_ command: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] %@ cannot be executed.\nCheck errors in the source code.\n", command))
    }

    @objc func showCannotOverwriteError(_ path: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] %@ cannot be overwritten.\n", path))
    }

    @objc func showCannotCreateDirectoryError(_ dir: String) {
        UtilityC.printStdErr(String(format: "tex2img: [Error] Directory %@ cannot be overwritten.\n", dir))
    }

    @objc func showCompileError() {
        UtilityC.printStdErr("tex2img: [Error] A TeX compile error occurred.\nCheck errors in the source code.\n")
    }

    @objc func showImageSizeError() {
        UtilityC.printStdErr("tex2img: [Error] An image format error occurred.\nThe image size may be too large.\nTry lower the resolution level.\n")
    }

    @objc func appendOutputAndScroll(_ str: String, quiet: Bool) {
        if !quiet {
            print(str, terminator: "")
        }
    }

    @objc func showErrorsIgnoredWarning() {
        UtilityC.printStdErr("tex2img: [Warning] Some errors were ignored. The result may be different from what you expected.\n")
    }

    @objc func showPageSkippedWarning(_ pages: [NSNumber]) {
        if pages.count > 1 {
            let joined = pages.map { $0.stringValue }.joined(separator: ", ")
            UtilityC.printStdErr(String(format: "tex2img: [Warning] Page %@ were empty and they were skipped.\n", joined))
        } else if let page = pages.first {
            UtilityC.printStdErr(String(format: "tex2img: [Warning] Page %ld was empty and it was skipped.\n", page.intValue))
        }
    }

    @objc func showWhitePageWarning(_ pages: [NSNumber]) {
        if pages.count > 1 {
            let joined = pages.map { $0.stringValue }.joined(separator: ", ")
            UtilityC.printStdErr(String(format: "tex2img: [Warning] Page %@ were empty and white pages were generated.\n", joined))
        } else if let page = pages.first {
            UtilityC.printStdErr(String(format: "tex2img: [Warning] Page %ld was empty and a white page was generated.\n", page.intValue))
        }
    }

    @objc func previewFiles(_ files: [String], withApplication app: String) {
        Utility.previewFiles(files, app: app)
    }

    @objc func printResult(_ generatedFiles: [String], quiet: Bool) {
        let count = generatedFiles.count
        guard !quiet else { return }

        appendOutputAndScroll("\n", quiet: quiet)

        if count > 1 {
            appendOutputAndScroll(String(format: "TeX2img: %ld files were generated.\n", count), quiet: quiet)
            appendOutputAndScroll("Generated files:\n", quiet: quiet)
        } else {
            appendOutputAndScroll(String(format: "TeX2img: %ld file was generated.\n", count), quiet: quiet)
            appendOutputAndScroll("Generated file:\n", quiet: quiet)
        }

        for path in generatedFiles {
            appendOutputAndScroll(String(format: "%@\n", path), quiet: quiet)
        }
    }

    @objc func generationDidFinish(_ status: ExitStatus) {
    }

    @objc func exitCurrentThreadIfTaskKilled() {
    }
}