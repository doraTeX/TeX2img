import AppKit
import Foundation
import ImageIO
import Quartz
import CoreServices

private let resolutionScale = 5.0
private let emptyBBox = "%%BoundingBox: 0 0 0 0\n"
private let eaKey = "com.loveinequality.TeX2img"
private let targetExtensions = ["eps", "pdf", "svg", "svgz", "jpg", "png", "gif", "tiff", "bmp"]
private let bitmapExtensions = ["png", "jpg", "gif", "tiff", "bmp"]
private let mergeableExtensions = ["pdf", "tiff", "gif", "svg", "svgz"]

protocol OutputController: AnyObject {
    func showExtensionError()
    func showNotFoundError(_ aPath: String)
    func latexExists(atPath latexPath: String, dviDriverPath: String, gsPath: String) -> Bool
    func epstopdfExists() -> Bool
    func mudrawExists() -> Bool
    func pdftopsExists() -> Bool
    func showFileFormatError(_ aPath: String)
    func showFileGenerationError(_ aPath: String)
    func showExecError(_ command: String)
    func showCannotOverwriteError(_ path: String)
    func showCannotCreateDirectoryError(_ dir: String)
    func showCompileError()
    func showImageSizeError()
    func appendOutputAndScroll(_ str: String, quiet: Bool)
    func prepareOutputTextView()
    func releaseOutputTextView()
    func showOutputWindow()
    func showMainWindow()
    func showErrorsIgnoredWarning()
    func showPageSkippedWarning(_ pages: [NSNumber])
    func showWhitePageWarning(_ pages: [NSNumber])
    func execCommand(_ command: String, atDirectory path: String, withArguments arguments: [String], quiet: Bool) -> Bool
    func previewFiles(_ files: [String], withApplication app: String)
    func printResult(_ generatedFiles: [String], quiet: Bool)
    func generationDidFinish(_ status: ExitStatus)
    func exitCurrentThreadIfTaskKilled()
}

@objc(Converter)
class Converter: NSObject {
    // MARK: - Public properties

    var keepPageSizeFlag = false
    var leftMargin: Int = 0
    var rightMargin: Int = 0
    var topMargin: Int = 0
    var bottomMargin: Int = 0
    var pageBoxType: CGPDFBox = .mediaBox

    // MARK: - Private properties

    private var latexPath = ""
    private var dviDriverPath = ""
    private var gsPath = ""
    private var encoding = ""
    private var outputFilePath = ""
    private var preambleStr = ""
    private var resolutionLevel: Float = 0
    private var dpi: Int = 0
    private var guessCompilation = false
    private var numberOfCompilation: Int = 0
    private var leaveTextFlag = false
    private var transparentFlag = false
    private var plainTextFlag = false
    private var deleteDisplaySizeFlag = false
    private var mergeOutputsFlag = false
    private var showOutputWindowFlag = false
    private var sendNotificationFlag = false
    private var previewFlag = false
    private var deleteTmpFileFlag = false
    private var autoPasteFlag = false
    private var embedInIllustratorFlag = false
    private var ungroupFlag = false
    private var ignoreErrorsFlag = false
    private var utfExportFlag = false
    private var quietFlag = false
    private var autoPasteDestination: Int = 0
    private weak var controller: OutputController?
    private let fileManager = FileManager.default
    private var workingDirectoryType: Int = 0
    private var workingDirectory = ""
    private var tempFileBaseName = ""
    private var epstopdfPath = ""
    private var mudrawPath = ""
    private var pdftopsPath = ""
    private var pageCount: Int = 1
    private var useBP = false
    private var speedPriorityMode = false
    private var embedSource = false
    private var copyToClipboard = false
    private var additionalInputPath: String?
    private var pdfInputMode = false
    private var psInputMode = false
    private var errorsIgnored = false
    private var delay: Float = 0
    private var loopCount: Int = 0
    private var usingNewGsFlag: NSNumber?
    private var emptyPageFlags = [NSNumber]()
    private var whitePageFlags = [NSNumber]()
    private var bboxDictionary = [String: String]()
    private var fillColor = NSColor.white

    // MARK: - Initialization

    init(profile aProfile: NSDictionary) {
        super.init()
        pageCount = 1

        latexPath = aProfile.stringForKey(LatexPathKey) ?? ""
        dviDriverPath = aProfile.stringForKey(DviDriverPathKey) ?? ""
        gsPath = aProfile.stringForKey(GsPathKey) ?? ""
        epstopdfPath = aProfile.stringForKey(EpstopdfPathKey) ?? ""
        mudrawPath = aProfile.stringForKey(MudrawPathKey) ?? ""
        pdftopsPath = aProfile.stringForKey(PdftopsPathKey) ?? ""
        guessCompilation = aProfile.boolForKey(GuessCompilationKey)
        numberOfCompilation = aProfile.integerForKey(NumberOfCompilationKey)

        outputFilePath = ((aProfile.stringForKey(OutputFileKey) ?? "") as NSString).standardizingPath
        preambleStr = aProfile.stringForKey(PreambleKey) ?? ""

        encoding = aProfile.stringForKey(EncodingKey) ?? ""
        resolutionLevel = aProfile.floatForKey(ResolutionKey) / Float(resolutionScale)
        dpi = aProfile.integerForKey(DPIKey)
        leftMargin = aProfile.integerForKey(LeftMarginKey)
        rightMargin = aProfile.integerForKey(RightMarginKey)
        topMargin = aProfile.integerForKey(TopMarginKey)
        bottomMargin = aProfile.integerForKey(BottomMarginKey)
        leaveTextFlag = !aProfile.boolForKey(GetOutlineKey)
        transparentFlag = aProfile.boolForKey(TransparentKey)
        plainTextFlag = aProfile.boolForKey(PlainTextKey)
        deleteDisplaySizeFlag = aProfile.boolForKey(DeleteDisplaySizeKey)
        mergeOutputsFlag = aProfile.boolForKey(MergeOutputsKey)
        keepPageSizeFlag = aProfile.boolForKey(KeepPageSizeKey)
        showOutputWindowFlag = aProfile.boolForKey(ShowOutputWindowKey)
        sendNotificationFlag = aProfile.boolForKey(SendNotificationKey)
        previewFlag = aProfile.boolForKey(PreviewKey)
        deleteTmpFileFlag = aProfile.boolForKey(DeleteTmpFileKey)
        copyToClipboard = aProfile.boolForKey(CopyToClipboardKey)
        autoPasteFlag = aProfile.boolForKey(AutoPasteKey)
        autoPasteDestination = aProfile.integerForKey(AutoPasteDestinationKey)
        embedInIllustratorFlag = aProfile.boolForKey(EmbedInIllustratorKey)
        ungroupFlag = aProfile.boolForKey(UngroupKey)
        ignoreErrorsFlag = aProfile.boolForKey(IgnoreErrorKey)
        utfExportFlag = aProfile.boolForKey(UtfExportKey)
        quietFlag = aProfile.boolForKey(QuietKey)
        controller = aProfile[ControllerKey] as? OutputController
        useBP = aProfile.integerForKey(UnitKey) == BP_UNIT_TAG
        speedPriorityMode = aProfile.integerForKey(PriorityKey) == SPEED_PRIORITY_TAG
        embedSource = aProfile.boolForKey(EmbedSourceKey)
        pageBoxType = CGPDFBox(rawValue: Int32(aProfile.integerForKey(PageBoxKey))) ?? .mediaBox
        delay = aProfile.floatForKey(DelayKey)
        loopCount = aProfile.integerForKey(LoopCountKey)
        fillColor = aProfile.colorForKey(FillColorKey) ?? .white
        workingDirectoryType = aProfile.integerForKey(WorkingDirectoryTypeKey)

        switch workingDirectoryType {
        case Int(WorkingDirectoryCurrent):
            workingDirectory = aProfile.stringForKey(WorkingDirectoryPathKey) ?? ""
        default:
            workingDirectory = fileManager.temporaryDirectory.path
        }

        usingNewGsFlag = nil
        additionalInputPath = nil
        pdfInputMode = false
        psInputMode = false
        errorsIgnored = false

        tempFileBaseName = String(format: "temp%d-%@", getpid(), NSString.UUIDString())
        bboxDictionary = [:]
    }

    static func converter(withProfile aProfile: NSDictionary) -> Converter {
        return Converter(profile: aProfile)
    }

    convenience init(profileDictionary: [String: Any]) {
        self.init(profile: profileDictionary as NSDictionary)
    }

    // MARK: - Thread control

    private func exitCurrentThread() {
        Thread.current.cancel()
        if Thread.current.isCancelled {
            deleteTemporaryFiles()
            controller?.generationDidFinish(.aborted)
            Thread.exit()
        }
    }

    // MARK: - TeX source writing

    private func substituteUTF(_ dataString: String) -> NSMutableString {
        return NSMutableString(string: (dataString as NSString).stringByReplacingUnicodeCharactersWithUTF())
    }

    private func writeStringWithYenBackslashConverting(_ targetString: String, toFile path: String) -> Bool {
        let mstr = NSMutableString(string: targetString)
        mstr.replaceYenWithBackSlash()

        var output = mstr
        if utfExportFlag {
            output = substituteUTF(mstr as String)
        }

        let enc: UInt
        if encoding == PTEX_ENCODING_SJIS {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosJapanese.rawValue))
        } else if encoding == PTEX_ENCODING_EUC {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_JP.rawValue))
        } else if encoding == PTEX_ENCODING_JIS {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.ISO_2022_JP.rawValue))
        } else {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringBuiltInEncodings.UTF8.rawValue))
        }

        return (try? output.write(toFile: path, atomically: false, encoding: enc)) != nil
    }

    private func preliminaryCommandsForEnvironmentVariables() -> NSMutableString {
        let cmdline = NSMutableString(format: "export PATH=$PATH:%@:%@;",
                                        (((latexPath as NSString).programPath as NSString).deletingLastPathComponent as NSString).stringByQuotingWithDoubleQuotations(),
                                        (((gsPath as NSString).programPath as NSString).deletingLastPathComponent as NSString).stringByQuotingWithDoubleQuotations())

        if let additionalInputPath {
            cmdline.appendFormat("export TEXINPUTS=\"%@:`kpsewhich -progname=%@ -expand-var=\\\\$TEXINPUTS`\";", additionalInputPath, (latexPath as NSString).programName)
        }

        return cmdline
    }

    private func compile(withArguments arguments: [String]) -> Bool {
        let cmdline = preliminaryCommandsForEnvironmentVariables()
        cmdline.append(latexPath)
        return controller?.execCommand(cmdline as String, atDirectory: workingDirectory, withArguments: arguments, quiet: quietFlag) ?? false
    }

    private func tex2dvi(_ texFilePath: String) -> Bool {
        var arguments = ["-interaction=nonstopmode"]

        if encoding != PTEX_ENCODING_NONE {
            arguments.append("-kanji=" + encoding)
        }

        arguments.append((texFilePath as NSString).stringByQuotingWithDoubleQuotations())

        let auxFilePath = ((workingDirectory as NSString).appendingPathComponent(tempFileBaseName) as NSString).appendingPathExtension("aux")!

        if fileManager.fileExists(atPath: auxFilePath) && !((try? fileManager.removeItem(atPath: auxFilePath)) != nil) {
            return false
        }

        var success = compile(withArguments: arguments)
        if !success && !ignoreErrorsFlag { return false }

        if guessCompilation {
            guard let oldAuxData = try? Data(contentsOf: URL(fileURLWithPath: auxFilePath)) else { return success }
            let relaxData = "\\relax \n".data(using: .utf8)!
            if oldAuxData == relaxData { return success }

            for i in 1..<numberOfCompilation {
                success = compile(withArguments: arguments)
                if !success && !ignoreErrorsFlag { return false }
                guard let newAuxData = try? Data(contentsOf: URL(fileURLWithPath: auxFilePath)) else { return success }
                if newAuxData == oldAuxData { return success }
            }
        } else {
            for _ in 1..<numberOfCompilation {
                success = compile(withArguments: arguments)
                if !success && !ignoreErrorsFlag { return false }
            }
        }

        return success
    }

    private func execDviDriver(_ dviFilePath: String) -> Bool {
        let cmdline = preliminaryCommandsForEnvironmentVariables()
        cmdline.append(dviDriverPath)

        let status = controller?.execCommand(cmdline as String, atDirectory: workingDirectory, withArguments: [(dviFilePath as NSString).stringByQuotingWithDoubleQuotations()], quiet: quietFlag) ?? false
        controller?.appendOutputAndScroll("\n", quiet: quietFlag)
        return status
    }

    private func ps2pdf(_ psFilePath: String, outputFile pdfFilePath: String) -> Bool {
        let cmdline = preliminaryCommandsForEnvironmentVariables()
        cmdline.append(gsPath)

        let status = controller?.execCommand(cmdline as String,
                                             atDirectory: workingDirectory,
                                             withArguments: ["-dSAFER",
                                                             "-dNOPAUSE",
                                                             "-dBATCH",
                                                             "-sOutputFile=" + (pdfFilePath as NSString).stringByQuotingWithDoubleQuotations(),
                                                             "-sDEVICE=pdfwrite",
                                                             "-dCompatibilityLevel=1.5",
                                                             "-dAutoRotatePages=/None",
                                                             "-f",
                                                             (psFilePath as NSString).stringByQuotingWithDoubleQuotations()],
                                             quiet: quietFlag) ?? false
        controller?.appendOutputAndScroll("\n", quiet: quietFlag)

        if !status {
            controller?.showExecError("Ghostscript")
        }

        return status
    }

    func bboxString(ofPdf pdfPath: String, page: Int, hires: Bool) -> String? {
        let key = String(format: "%@-%ld-%d", (pdfPath as NSString).lastPathComponent, page, hires ? 1 : 0)

        if bboxDictionary[key] == nil {
            let bboxFileName = tempFileBaseName + "-bbox"
            let bboxFilePath = (workingDirectory as NSString).appendingPathComponent(bboxFileName)

            controller?.appendOutputAndScroll("TeX2img: Getting the bounding box...\n\n", quiet: quietFlag)

            let success = controller?.execCommand((gsPath as NSString).programPath,
                                                  atDirectory: workingDirectory,
                                                  withArguments: ["-dBATCH",
                                                                  "-dNOPAUSE",
                                                                  "-sDEVICE=bbox",
                                                                  "-c '<< /WhiteIsOpaque true >> setpagedevice'",
                                                                  "-f",
                                                                  ((pdfPath as NSString).lastPathComponent as NSString).stringByQuotingWithDoubleQuotations(),
                                                                  "> " + bboxFileName],
                                                  quiet: quietFlag) ?? false

            guard let lines = extractBoundingBoxLines(from: bboxFilePath) as? [String] else {
                try? fileManager.removeItem(atPath: bboxFilePath)
                controller?.showExecError("Ghostscript")
                return nil
            }
            try? fileManager.removeItem(atPath: bboxFilePath)

            var currentPage = 0
            var parseSuccess = success

            for line in lines {
                if line.count >= 5 && (line as NSString).substring(with: NSRange(location: 0, length: 5)) == "Page " {
                    currentPage = Int((line as NSString).substring(from: 5)) ?? 0
                    parseSuccess = true
                    continue
                }
                if line.count >= 14 && (line as NSString).substring(with: NSRange(location: 0, length: 14)) == "%%BoundingBox:" {
                    let dictKey = String(format: "%@-%ld-0", (pdfPath as NSString).lastPathComponent, currentPage)
                    bboxDictionary[dictKey] = line + "\n"
                    continue
                }
                if line.count >= 19 && (line as NSString).substring(with: NSRange(location: 0, length: 19)) == "%%HiResBoundingBox:" {
                    let dictKey = String(format: "%@-%ld-1", (pdfPath as NSString).lastPathComponent, currentPage)
                    bboxDictionary[dictKey] = line + "\n"
                    continue
                }
            }

            if !parseSuccess {
                controller?.showExecError("Ghostscript")
                return nil
            }
        }

        return bboxDictionary[key]
    }

    private func isEmptyPage(_ pdfPath: String, page: UInt, success: inout Bool) -> Bool {
        guard let bbStr = bboxString(ofPdf: pdfPath, page: Int(page), hires: false) else {
            success = false
            return false
        }
        success = true
        return bbStr == emptyBBox
    }

    private func willEmptyPageBeCreated(_ pdfPath: String, page: UInt, success: inout Bool) -> Bool {
        let isEmpty = isEmptyPage(pdfPath, page: page, success: &success)
        if !success { return false }
        return !keepPageSizeFlag && isEmpty && ((leftMargin + rightMargin == 0) || (topMargin + bottomMargin == 0))
    }


    private func pdfcrop(_ pdfPath: String,
                         outputFileName: String,
                         page: UInt,
                         addMargin: Bool,
                         useCache: Bool,
                         fillBackground: Bool) -> Bool {
        let cropFileBasePath = String(format: "%@-pdfcrop-%ld%d",
                                      (workingDirectory as NSString).appendingPathComponent(tempFileBaseName), page, addMargin ? 1 : 0)
        let cropPdfSourcePath = (cropFileBasePath as NSString).appendingPathExtension("pdf")!

        if useCache && fileManager.fileExists(atPath: cropPdfSourcePath) {
            try? fileManager.removeItem(atPath: outputFileName)
            return (try? fileManager.copyItem(atPath: cropPdfSourcePath, toPath: outputFileName)) != nil
        }

        controller?.appendOutputAndScroll("TeX2img: Adjusting bounding boxes...\n\n", quiet: quietFlag)

        var success = generateCroppedPDF(of: pdfPath, page: Int(page), to: cropPdfSourcePath, addMargin: addMargin)

        try? fileManager.removeItem(atPath: outputFileName)

        if success {
            if !useCache || page > 0 {
                success = (try? fileManager.moveItem(atPath: cropPdfSourcePath, toPath: outputFileName)) != nil
            } else {
                success = (try? fileManager.copyItem(atPath: cropPdfSourcePath, toPath: outputFileName)) != nil
            }
        }

        if !transparentFlag && fillBackground {
            PDFDocument.fillBackground(of: (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).lastPathComponent), with: fillColor)
        }

        return success
    }

    private func isUsingNewGS() -> Bool {
        if let usingNewGsFlag {
            return usingNewGsFlag.boolValue
        }

        var result = true
        let gsVerFileName = tempFileBaseName + "-gsver"
        let gsVerFilePath = (workingDirectory as NSString).appendingPathComponent(gsVerFileName)

        let success = controller?.execCommand((gsPath as NSString).programPath,
                                              atDirectory: workingDirectory,
                                              withArguments: ["--version", "> " + gsVerFileName],
                                              quiet: true) ?? false

        if !success {
            controller?.showExecError("Ghostscript")
            return true
        }

        let versionString = try? String(contentsOfFile: gsVerFilePath, encoding: .utf8)
        try? fileManager.removeItem(atPath: gsVerFilePath)

        if let versionString,
           let regex = try? NSRegularExpression(pattern: "\\d+(?:\\.\\d+)?"),
           let match = regex.firstMatch(in: versionString, range: NSRange(location: 0, length: versionString.count)) {
            let versionSubstring = (versionString as NSString).substring(with: match.range(at: 0))
            let version = Double(versionSubstring) ?? 0
            if version < 9.15 {
                result = false
            }
        }

        usingNewGsFlag = NSNumber(value: result)
        return result
    }

    private func replaceEpsBBox(_ epsName: String, withBBoxOfPdf pdfName: String, page: UInt) -> Bool {
        let epsPath = (workingDirectory as NSString).appendingPathComponent(epsName)
        guard let bbStr = bboxString(ofPdf: pdfName, page: Int(page), hires: false) else { return false }
        if bbStr == emptyBBox { return true }

        var hiresBbStr = bboxString(ofPdf: pdfName, page: Int(page), hires: true)
        let bbContent = bbStr.replacingOccurrences(of: "%%BoundingBox: ", with: "")
        hiresBbStr = hiresBbStr?.replacingOccurrences(of: "%%HiResBoundingBox: ", with: "") ?? bbContent

        replaceBBoxOf(epsPath: epsPath, boundingBox: bbContent, hiresBoundingBox: hiresBbStr!)
        return true
    }

    private func replaceEpsBBoxWithEmptyBBox(_ epsName: String) -> Bool {
        let epsPath = (workingDirectory as NSString).appendingPathComponent(epsName)
        replaceBBoxOf(epsPath: epsPath, boundingBox: "0 0 0 0\n", hiresBoundingBox: "0.000000 0.000000 0.000000 0.000000\n")
        return true
    }

    private func replaceEpsBBox(_ epsName: String, withPageBoxOfPdf pdfName: String, page: UInt) -> Bool {
        let pageBox = PDFPageBox(filePath: (workingDirectory as NSString).appendingPathComponent(pdfName), page: Int(page))
        let epsPath = (workingDirectory as NSString).appendingPathComponent(epsName)
        let bbStr = pageBox?.bboxString(of: pageBoxType, hires: false, addHeader: false) ?? ""
        let hiresBbStr = pageBox?.bboxString(of: pageBoxType, hires: true, addHeader: false) ?? ""

        replaceBBoxOf(epsPath: epsPath, boundingBox: bbStr, hiresBoundingBox: hiresBbStr)
        return true
    }

    private func pdf2eps(_ pdfName: String, outputFileName epsName: String, resolution: Int, page: UInt) -> Bool {
        var arguments = ["-dNOPAUSE",
                         "-dBATCH",
                         "-dAutoRotatePages=/None",
                         String(format: "-r%ld", resolution),
                         String(format: "-sOutputFile=%@", (epsName as NSString).stringByQuotingWithDoubleQuotations()),
                         String(format: "-dFirstPage=%lu", page),
                         String(format: "-dLastPage=%lu", page)]

        if isUsingNewGS() {
            arguments += ["-sDEVICE=eps2write", "-dNoOutputFonts", "-dCompressPages=true", "-dASCII85EncodePages=false"]
        } else {
            arguments += ["-sDEVICE=epswrite", "-dNOCACHE"]
        }

        arguments.append((pdfName as NSString).stringByQuotingWithDoubleQuotations())

        let status = controller?.execCommand(gsPath, atDirectory: workingDirectory, withArguments: arguments, quiet: quietFlag) ?? false

        if !status {
            controller?.showExecError("Ghostscript")
            return false
        }

        var success = true
        let isEmpty = isEmptyPage(pdfName, page: page, success: &success)

        if !success { return false }

        if isEmpty && !keepPageSizeFlag {
            return replaceEpsBBoxWithEmptyBBox(epsName)
        }

        if keepPageSizeFlag {
            return replaceEpsBBox(epsName, withPageBoxOfPdf: pdfName, page: page)
        } else {
            return replaceEpsBBox(epsName, withBBoxOfPdf: pdfName, page: page)
        }
    }

    private func pdf2pdf(_ pdfName: String, outputFileName: String, resolution: Int, page: UInt) -> Bool {
        let pdfOutName = tempFileBaseName + "-pdfwrite.pdf"
        let arguments = ["-dNOPAUSE",
                         "-dBATCH",
                         "-sDEVICE=pdfwrite",
                         "-dCompatibilityLevel=1.5",
                         "-dNoOutputFonts",
                         String(format: "-r%ld", resolution),
                         String(format: "-sOutputFile=%@", pdfOutName),
                         String(format: "-dFirstPage=%lu", page),
                         String(format: "-dLastPage=%lu", page),
                         "-dAutoRotatePages=/None",
                         "-f",
                         pdfName]

        let status = controller?.execCommand(gsPath, atDirectory: workingDirectory, withArguments: arguments, quiet: quietFlag) ?? false

        if !status {
            controller?.showExecError("Ghostscript")
            return false
        }

        let thisOutputPath = (workingDirectory as NSString).appendingPathComponent(outputFileName)
        try? fileManager.removeItem(atPath: thisOutputPath)
        try? fileManager.moveItem(atPath: (workingDirectory as NSString).appendingPathComponent(pdfOutName), toPath: thisOutputPath)

        return true
    }

    private func epstopdf(_ epsName: String, outputFileName pdfName: String) -> Bool {
        guard controller?.epstopdfExists() == true else { return false }

        let temporaryOutputPdfFileName = tempFileBaseName + "-out.pdf"

        let hiresOption: String
        if #available(macOS 10.11, *) {
            hiresOption = "--hires"
        } else {
            hiresOption = "--nohires"
        }

        let exportPath = ((gsPath as NSString).programPath as NSString).deletingLastPathComponent
        let command = String(format: "export PATH=\"%@\";/usr/bin/perl \"%@\"", exportPath, epstopdfPath)

        controller?.execCommand(command,
                              atDirectory: workingDirectory,
                              withArguments: [String(format: "--outfile=%@", (temporaryOutputPdfFileName as NSString).stringByQuotingWithDoubleQuotations()),
                                              hiresOption,
                                              epsName],
                              quiet: quietFlag)

        let outFilePath = (workingDirectory as NSString).appendingPathComponent((pdfName as NSString).lastPathComponent)
        try? fileManager.removeItem(atPath: outFilePath)
        try? fileManager.moveItem(atPath: (workingDirectory as NSString).appendingPathComponent((temporaryOutputPdfFileName as NSString).lastPathComponent), toPath: outFilePath)
        return true
    }

    private func eps2pdf(_ epsName: String, outputFileName pdfName: String, addMargin: Bool) -> Bool {
        if addMargin && (leftMargin + rightMargin + topMargin + bottomMargin > 0) {
            let trimFileName = String(format: "%@-trim.pdf", (epsName as NSString).deletingPathExtension)
            return epstopdf(epsName, outputFileName: trimFileName) &&
                pdfcrop(trimFileName, outputFileName: pdfName, page: 0, addMargin: true, useCache: false, fillBackground: false)
        } else {
            return epstopdf(epsName, outputFileName: pdfName)
        }
    }

    private func fillBackground(_ bitmapRep: NSBitmapImageRep) -> NSBitmapImageRep {
        let srcImage = NSImage()
        srcImage.addRepresentation(bitmapRep)
        let size = srcImage.size

        let backgroundImage = NSImage(size: size)
        backgroundImage.lockFocus()
        fillColor.set()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: size.width, height: size.height))
        srcImage.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        backgroundImage.unlockFocus()

        return NSBitmapImageRep(data: backgroundImage.tiffRepresentation!)!
    }

    private func gif89aData(fromGIF87aData gif87aData: Data?) -> Data? {
        guard var gif87aData else { return nil }
        var gif89aData = NSMutableData(data: gif87aData)
        var gif89a: CChar = CChar(UnicodeScalar("9").value)
        gif89aData.replaceBytes(in: NSRange(location: 4, length: 1), withBytes: &gif89a, length: 1)
        return gif89aData as Data
    }


    private func pdf2image(_ pdfFilePath: String, outputFileName: String, page: UInt, crop: Bool) -> Bool {
        let extension_ = (outputFileName as NSString).pathExtension.lowercased()
        let cropPdfFilePath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName + "-image.pdf")

        var success = true
        let isEmpty = willEmptyPageBeCreated(pdfFilePath, page: page, success: &success)
        if !success { return false }

        if crop && isEmpty { return true }

        var sourcePdfPath = pdfFilePath
        if crop {
            let cropSuccess = pdfcrop(pdfFilePath, outputFileName: cropPdfFilePath, page: 0, addMargin: false, useCache: true, fillBackground: false)
            if !cropSuccess {
                controller?.showCannotOverwriteError(cropPdfFilePath)
                return false
            }
            sourcePdfPath = cropPdfFilePath
        }

        guard let pdfDoc = PDFDocument(filePath: sourcePdfPath),
              let pdfPage = pdfDoc.page(at: Int(page) - 1),
              let pageData = pdfPage.dataRepresentation else {
            controller?.showFileGenerationError(crop ? cropPdfFilePath : pdfFilePath)
            return false
        }

        guard let pdfImageRep = NSPDFImageRep(data: pageData) else {
            controller?.showFileGenerationError(crop ? cropPdfFilePath : pdfFilePath)
            return false
        }

        controller?.appendOutputAndScroll(String(format: "TeX2img: PDF → %@ (Page %ld)\n", extension_.uppercased(), page), quiet: quietFlag)

        let rect = pdfImageRep.bounds
        let width = rect.size.width
        let height = rect.size.height

        var thisLeftMargin = CGFloat(leftMargin)
        var thisRightMargin = CGFloat(rightMargin)
        var thisTopMargin = CGFloat(topMargin)
        var thisBottomMargin = CGFloat(bottomMargin)

        if useBP {
            thisLeftMargin *= CGFloat(resolutionLevel)
            thisRightMargin *= CGFloat(resolutionLevel)
            thisTopMargin *= CGFloat(resolutionLevel)
            thisBottomMargin *= CGFloat(resolutionLevel)
        } else {
            let factor = NSScreen.main?.backingScaleFactor ?? 1.0
            thisLeftMargin /= factor
            thisRightMargin /= factor
            thisTopMargin /= factor
            thisBottomMargin /= factor
        }

        let size = NSSize(width: Int(width * CGFloat(resolutionLevel)) + Int(thisLeftMargin + thisRightMargin),
                          height: Int(height * CGFloat(resolutionLevel)) + Int(thisTopMargin + thisBottomMargin))

        guard size.height > 0 && size.width > 0 else { return false }

        let image = NSImage(size: size)
        image.lockFocus()
        pdfImageRep.draw(in: NSRect(x: thisLeftMargin, y: thisBottomMargin,
                                    width: width * CGFloat(resolutionLevel),
                                    height: height * CGFloat(resolutionLevel)))
        image.unlockFocus()

        var imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)!

        var outputData: Data?
        if extension_ == "jpg" {
            imageRep = fillBackground(imageRep)
            outputData = imageRep.representation(usingType: kUTTypeJPEG, usingDPI: dpi)
        } else if extension_ == "png" {
            if !transparentFlag {
                imageRep = fillBackground(imageRep)
            }
            outputData = imageRep.representation(usingType: kUTTypePNG, usingDPI: dpi)
        } else if extension_ == "gif" {
            if !transparentFlag {
                imageRep = fillBackground(imageRep)
            }
            outputData = gif89aData(fromGIF87aData: imageRep.representation(using: .gif, properties: [:]))
        } else if extension_ == "tiff" {
            if !transparentFlag {
                imageRep = fillBackground(imageRep)
            }
            outputData = imageRep.representation(usingType: kUTTypeTIFF, usingDPI: dpi)
        } else if extension_ == "bmp" {
            imageRep = fillBackground(imageRep)
            outputData = imageRep.representation(usingType: kUTTypeBMP, usingDPI: dpi)
        }

        let outputPath = (workingDirectory as NSString).appendingPathComponent(outputFileName)
        try? outputData?.write(to: URL(fileURLWithPath: outputPath))

        guard NSImageRep(contentsOfFile: outputPath) != nil else {
            controller?.showImageSizeError()
            return false
        }

        return true
    }

    private func pdf2plainTextEps(_ pdfName: String, outputFileName epsName: String, page: UInt) -> Bool {
        guard controller?.pdftopsExists() == true else { return false }

        let pageStr = String(page)
        let arguments = ["-f", pageStr, "-l", pageStr, "-eps", pdfName, epsName]

        return controller?.execCommand((pdftopsPath as NSString).stringByQuotingWithDoubleQuotations(),
                                     atDirectory: workingDirectory,
                                     withArguments: arguments,
                                     quiet: quietFlag) ?? false
    }

    private func mergeTIFFFiles(_ sourcePaths: [String], toPath destPath: String) -> Bool {
        var arguments = ["-cat"]
        arguments += sourcePaths.map { ($0 as NSString).stringByQuotingWithDoubleQuotations() }
        arguments += ["-out", ((destPath as NSString).lastPathComponent as NSString).stringByQuotingWithDoubleQuotations()]

        var success = controller?.execCommand("/usr/bin/tiffutil",
                                              atDirectory: workingDirectory,
                                              withArguments: arguments,
                                              quiet: quietFlag) ?? false
        if success {
            success = copyTarget(from: (workingDirectory as NSString).appendingPathComponent((destPath as NSString).lastPathComponent), toPath: destPath)
        }
        return success
    }

    private func generateAnimatedGIF(from sourcePaths: [String], toPath destPath: String) -> Bool {
        let frameProperties: [String: Any] = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: delay]]
        let gifProperties: [String: Any] = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: loopCount]]

        var gifData = CFDataCreateMutable(kCFAllocatorDefault, 0)!
        let destination = CGImageDestinationCreateWithData(gifData, kUTTypeGIF, sourcePaths.count, nil)!
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        var success = true

        for path in sourcePaths {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let rep = NSBitmapImageRep(data: data),
                  let cgImage = rep.cgImage else {
                success = false
                break
            }
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        if success {
            CGImageDestinationFinalize(destination)
            let animatedData = gif89aData(fromGIF87aData: gifData as Data)
            if let animatedData {
                let tempOutPath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName + "-out.gif")
                try? fileManager.removeItem(atPath: tempOutPath)
                success = (try? animatedData.write(to: URL(fileURLWithPath: tempOutPath))) != nil
                if success {
                    success = copyTarget(from: tempOutPath, toPath: destPath)
                }
            } else {
                success = false
            }
        }

        return success
    }

    private func generateAnimatedSVG(from sourcePaths: [String], toPath destPath: String) -> Bool {
        var result = ""
        var svgIds = [String]()

        for (idx, path) in sourcePaths.enumerated() {
            guard var svg = try? String(contentsOfFile: path, encoding: .utf8) else { continue }

            var lines = svg.components(separatedBy: "\n")
            if lines.count >= 2 {
                lines.removeSubrange(0..<2)
            }
            svg = lines.joined(separator: "\n")

            let idPrefix = String(format: "%@-%ld-",
                                  ((destPath as NSString).lastPathComponent as NSString).deletingPathExtension.replacingOccurrences(of: " ", with: "_"),
                                  idx)

            svg = svg.replacingOccurrences(of: " id=\"", with: " id=\"\(idPrefix)")

            if let regex = try? NSRegularExpression(pattern: "(?<!\\&)\\#(?![0-9a-f]{6}(?![0-9a-f]))") {
                let range = NSRange(location: 0, length: svg.count)
                svg = regex.stringByReplacingMatches(in: svg, options: [], range: range, withTemplate: "#\(idPrefix)")
            }

            let svgId = idPrefix + "svg"
            svgIds.append("#\(svgId)")

            let mstr = NSMutableString(string: svg)
            mstr.replaceFirstOccuarnce(ofString: "<svg ", replacment: "<svg id=\"\(svgId)\" ")
            result += mstr as String
        }

        let dur = Float(sourcePaths.count) * delay
        let repeatCount = loopCount == 0 ? "indefinite" : String(loopCount)
        let svgIdRefs = svgIds.joined(separator: ";")

        let output = String(format: "<?xml version=\"1.0\" standalone=\"no\"?>\n"
                            + "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
                            + "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\">\n"
                            + "<defs>%@</defs><use><animate attributeName=\"xlink:href\" begin=\"0s\" dur=\"%fs\" repeatCount=\"%@\" values=\"%@\" /></use></svg>",
                            result, dur, repeatCount, svgIdRefs)

        let tempOutPath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName + "-out.svg")
        try? fileManager.removeItem(atPath: tempOutPath)

        do {
            try output.write(toFile: tempOutPath, atomically: false, encoding: .utf8)
        } catch {
            return false
        }

        return copyTarget(from: tempOutPath, toPath: destPath)
    }

    private func pdf2svg(_ pdfFilePath: String, outputFileName svgFilePath: String, page: UInt, skipEmptyPage: Bool) -> Bool {
        guard controller?.mudrawExists() == true else { return false }

        if skipEmptyPage && page > 0 && page <= UInt(emptyPageFlags.count) && emptyPageFlags[Int(page) - 1].boolValue {
            return true
        }

        let arguments = ["-o", (svgFilePath as NSString).stringByQuotingWithDoubleQuotations(),
                         (pdfFilePath as NSString).stringByQuotingWithDoubleQuotations(),
                         String(format: "%ld", page)]

        let success = controller?.execCommand((mudrawPath as NSString).stringByQuotingWithDoubleQuotations(),
                                              atDirectory: workingDirectory,
                                              withArguments: arguments,
                                              quiet: quietFlag) ?? false
        if !success { return false }

        let outputtedSvgPath = (((svgFilePath as NSString).deletingPathExtension as NSString).appendingFormat("%ld", page) as NSString).appendingPathExtension("svg")!
        if fileManager.fileExists(atPath: outputtedSvgPath) {
            try? fileManager.removeItem(atPath: svgFilePath)
            do {
                try fileManager.moveItem(atPath: outputtedSvgPath, toPath: svgFilePath)
            } catch {
                return false
            }
        }

        if deleteDisplaySizeFlag {
            if var mstr = try? String(contentsOfFile: svgFilePath, encoding: .utf8) {
                let pattern = "width=\".+?\" height=\".+?\" "
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: mstr, range: NSRange(location: 0, length: mstr.count)) {
                    let nsstr = NSMutableString(string: mstr)
                    nsstr.replaceCharacters(in: match.range, with: "")
                    mstr = nsstr as String
                }
                try? mstr.write(toFile: svgFilePath, atomically: false, encoding: .utf8)
            }
        }

        return true
    }


    private func outlinePDF(_ pdfFileName: String,
                            intermediateOutlinedFileName: String,
                            outputFileName: String,
                            page: UInt,
                            addMargin: Bool,
                            useCache: Bool,
                            fillBackground fill: Bool) -> Bool {
        let extension_ = (outputFileName as NSString).pathExtension.lowercased()
        let lowResolution = Int(resolutionLevel * Float(Int(resolutionScale)) * 2 * 72)
        let resolution = speedPriorityMode ? lowResolution : 20016
        let trimFileName = tempFileBaseName + "-trim.pdf"

        if extension_ == "eps" {
            if isUsingNewGS() && plainTextFlag {
                _ = pdfcrop(pdfFileName, outputFileName: trimFileName, page: 0, addMargin: addMargin, useCache: useCache, fillBackground: false)

                var success = true
                let isEmpty = isEmptyPage(pdfFileName, page: page, success: &success)
                if !success { return false }

                if isEmpty {
                    _ = pdfcrop(pdfFileName, outputFileName: intermediateOutlinedFileName, page: page, addMargin: true, useCache: false, fillBackground: false)
                } else {
                    if !pdf2pdf(trimFileName, outputFileName: intermediateOutlinedFileName, resolution: resolution, page: page) ||
                        !fileManager.fileExists(atPath: (workingDirectory as NSString).appendingPathComponent(intermediateOutlinedFileName)) {
                        return false
                    }
                }

                if !pdf2plainTextEps(intermediateOutlinedFileName, outputFileName: outputFileName, page: 1) {
                    return false
                }
            } else {
                if !pdf2eps(pdfFileName, outputFileName: outputFileName, resolution: resolution, page: page) ||
                    !fileManager.fileExists(atPath: (workingDirectory as NSString).appendingPathComponent(outputFileName)) {
                    return false
                }
            }
        } else if extension_ == "pdf" {
            var success = true
            let isEmpty = isEmptyPage(pdfFileName, page: page, success: &success)
            if !success { return false }

            if isEmpty {
                _ = pdfcrop(pdfFileName, outputFileName: outputFileName, page: page, addMargin: addMargin, useCache: useCache, fillBackground: false)
            } else {
                if isUsingNewGS() {
                    _ = pdfcrop(pdfFileName, outputFileName: trimFileName, page: page, addMargin: addMargin, useCache: useCache, fillBackground: false)

                    if !pdf2pdf(trimFileName, outputFileName: outputFileName, resolution: resolution, page: 1) ||
                        !fileManager.fileExists(atPath: (workingDirectory as NSString).appendingPathComponent(outputFileName)) {
                        return false
                    }
                } else {
                    if !pdf2eps(pdfFileName, outputFileName: intermediateOutlinedFileName, resolution: resolution, page: page) ||
                        !fileManager.fileExists(atPath: (workingDirectory as NSString).appendingPathComponent(intermediateOutlinedFileName)) {
                        return false
                    }
                    _ = eps2pdf(intermediateOutlinedFileName, outputFileName: outputFileName, addMargin: addMargin)
                }
            }

            if fill && !transparentFlag {
                PDFDocument.fillBackground(of: (workingDirectory as NSString).appendingPathComponent(outputFileName), with: fillColor)
            }
        } else {
            return false
        }

        return true
    }

    private func modifyEpsForOutliningPaths(_ epsName: String) -> Bool {
        guard let epsData = try? Data(contentsOf: URL(fileURLWithPath: epsName)) else { return false }

        var newData = Data("/oldstroke /stroke load def\n/stroke {strokepath fill} def\n".utf8)
        newData.append(epsData)
        return (try? newData.write(to: URL(fileURLWithPath: epsName))) != nil
    }

    private func convertPDF(_ pdfFileName: String,
                            intermediateOutlinedFileName: String,
                            outputFileName: String,
                            page: UInt,
                            useCache: Bool,
                            skipEmptyPage: Bool) -> Bool {
        let extension_ = (outputFileName as NSString).pathExtension.lowercased()
        let outlinedPdfFileName = tempFileBaseName + "-outline.pdf"

        if emptyPageFlags.isEmpty {
            exitCurrentThread()
        }

        if skipEmptyPage && page > 0 && page <= UInt(emptyPageFlags.count) && emptyPageFlags[Int(page) - 1].boolValue {
            return true
        }

        if extension_ == "pdf" {
            _ = outlinePDF(pdfFileName,
                           intermediateOutlinedFileName: intermediateOutlinedFileName,
                           outputFileName: outputFileName,
                           page: page,
                           addMargin: true,
                           useCache: useCache,
                           fillBackground: true)
        } else if extension_ == "eps" {
            _ = outlinePDF(pdfFileName,
                           intermediateOutlinedFileName: outlinedPdfFileName,
                           outputFileName: intermediateOutlinedFileName,
                           page: page,
                           addMargin: false,
                           useCache: useCache,
                           fillBackground: false)

            if transparentFlag && (topMargin + bottomMargin + leftMargin + rightMargin > 0) {
                enlargeBoundingBox(of: (workingDirectory as NSString).appendingPathComponent(intermediateOutlinedFileName))
            }

            if fileManager.fileExists(atPath: outputFileName) {
                try? fileManager.removeItem(atPath: outputFileName)
            }
            try? fileManager.moveItem(atPath: (workingDirectory as NSString).appendingPathComponent(intermediateOutlinedFileName), toPath: outputFileName)
        } else {
            _ = outlinePDF(pdfFileName,
                           intermediateOutlinedFileName: intermediateOutlinedFileName,
                           outputFileName: outlinedPdfFileName,
                           page: page,
                           addMargin: false,
                           useCache: useCache,
                           fillBackground: false)

            if !pdf2image((workingDirectory as NSString).appendingPathComponent(outlinedPdfFileName),
                          outputFileName: outputFileName, page: 1, crop: false) {
                return false
            }
        }

        return true
    }

    private func copyTarget(from sourcePath: String, toPath destPath: String) -> Bool {
        if sourcePath == destPath { return true }

        let fileExists = fileManager.fileExists(atPath: destPath)

        if fileExists {
            if fileManager.isDirectory(atPath: destPath) || ((try? fileManager.removeItem(atPath: destPath)) == nil) {
                controller?.showCannotOverwriteError(destPath)
                return false
            }
        } else {
            let destDir = (destPath as NSString).deletingLastPathComponent
            let dirExists = fileManager.fileExists(atPath: destDir)

            if (!dirExists && ((try? fileManager.createDirectory(atPath: destDir, withIntermediateDirectories: true)) == nil)) ||
                (dirExists && !fileManager.isDirectory(atPath: destDir)) {
                controller?.showCannotCreateDirectoryError(destDir)
                return false
            }
        }

        return (try? fileManager.copyItem(atPath: sourcePath, toPath: destPath)) != nil
    }

    private func embedTeXSource(_ texFilePath: String, intoFile filePath: String) {
        guard embedSource,
              fileManager.isRegularFile(atPath: texFilePath) else { return }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: texFilePath)) else { return }

        var detectedEncoding: UInt = 0
        guard let contents = NSString.stringWithAutoEncodingDetectionOfData(data, detectedEncoding: &detectedEncoding) else { return }

        let extension_ = (filePath as NSString).pathExtension.lowercased()
        if extension_ == "pdf" {
            guard let doc = PDFDocument(filePath: filePath),
                  let page = doc.page(at: 0) else { return }

            let annotation = PDFAnnotationText(bounds: .zero)
            annotation.shouldDisplay = false
            annotation.shouldPrint = false
            annotation.contents = AnnotationHeader + contents

            page.addAnnotation(annotation)
            doc.write(to: URL(fileURLWithPath: filePath))
        }

        let target = filePath.withCString { $0 }
        contents.withCString { val in
            setxattr(target, eaKey, val, strlen(val), 0, 0)
        }
    }

    private func fileModificationDate(atPath filePath: String) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: filePath) else { return nil }
        return attributes[.modificationDate] as? Date
    }

    private func convertPDF(_ pdfFilePath: String, toOutlinedSVG svgFilePath: String, page: UInt) -> Bool {
        let baseName = (tempFileBaseName as NSString).pathStringByAppendingPageNumber(page)
        let outlinedPdfFileName = baseName + "-outline.pdf"
        let croppedPdfFileName = baseName + "-crop.pdf"
        let trimmedPdfFileName = baseName + "-trim.pdf"
        let tempEpsFileName = (baseName as NSString).appendingPathExtension("eps")!

        if isUsingNewGS() {
            if !pdfcrop(pdfFilePath, outputFileName: croppedPdfFileName, page: page, addMargin: true, useCache: true, fillBackground: false) {
                return false
            }

            let originalKeepPageSizeFlag = keepPageSizeFlag
            keepPageSizeFlag = true

            if !outlinePDF(croppedPdfFileName,
                           intermediateOutlinedFileName: outlinedPdfFileName,
                           outputFileName: outlinedPdfFileName,
                           page: 1,
                           addMargin: false,
                           useCache: false,
                           fillBackground: true) {
                keepPageSizeFlag = originalKeepPageSizeFlag
                return false
            }

            keepPageSizeFlag = originalKeepPageSizeFlag

            _ = pdf2svg(outlinedPdfFileName, outputFileName: svgFilePath, page: 1, skipEmptyPage: false)
            controller?.exitCurrentThreadIfTaskKilled()
        } else {
            if !pdfcrop(pdfFilePath, outputFileName: croppedPdfFileName, page: page, addMargin: false, useCache: true, fillBackground: false) {
                return false
            }

            if !outlinePDF(croppedPdfFileName,
                           intermediateOutlinedFileName: tempEpsFileName,
                           outputFileName: trimmedPdfFileName,
                           page: 1,
                           addMargin: true,
                           useCache: false,
                           fillBackground: true) {
                return false
            }

            _ = pdf2svg(trimmedPdfFileName, outputFileName: svgFilePath, page: 1, skipEmptyPage: false)
            controller?.exitCurrentThreadIfTaskKilled()
        }

        return true
    }

    private func gzipSVG(_ svgPath: String, toSVGZ svgzPath: String) -> Bool {
        return controller?.execCommand("/usr/bin/gzip",
                                       atDirectory: workingDirectory,
                                       withArguments: ["-cfq9",
                                                       (svgPath as NSString).stringByQuotingWithDoubleQuotations(),
                                                       "> " + (svgzPath as NSString).stringByQuotingWithDoubleQuotations()],
                                       quiet: quietFlag) ?? false
    }


    private func compileAndConvert() -> Bool {
        let texFilePath = String(format: "%@.tex", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))
        let dviFilePath = String(format: "%@.dvi", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))
        let psFilePath = String(format: "%@.ps", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))
        let pdfFilePath = String(format: "%@.pdf", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))
        let croppedPdfFilePath = String(format: "%@-crop.pdf", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))
        let pdfFileName = tempFileBaseName + ".pdf"
        let outputEpsFileName = tempFileBaseName + ".eps"
        var outputFileName = (outputFilePath as NSString).lastPathComponent
        var extension_ = (outputFilePath as NSString).pathExtension.lowercased()

        if extension_ == "svgz" {
            outputFileName = (outputFileName as NSString).stringByReplacingPathExtension("svg")
        }

        var texDate: Date?
        var dviDate: Date?
        var psDate: Date?
        var pdfDate: Date?
        var success = false
        var compilationSucceeded = false
        var requireDviDriver = false
        var requireGS = false

        errorsIgnored = false
        fileManager.changeCurrentDirectoryPath(workingDirectory)

        if !pdfInputMode && !psInputMode {
            success = tex2dvi(texFilePath)
            if !success {
                if ignoreErrorsFlag {
                    errorsIgnored = true
                } else {
                    controller?.showCompileError()
                    return false
                }
            }
            controller?.exitCurrentThreadIfTaskKilled()

            compilationSucceeded = false
            requireDviDriver = false
            texDate = fileModificationDate(atPath: texFilePath)

            if fileManager.fileExists(atPath: pdfFilePath) {
                pdfDate = fileModificationDate(atPath: pdfFilePath)
                if let pdfDate, let texDate, (pdfDate as NSDate).isNewerThan(texDate as NSDate) {
                    requireDviDriver = false
                    compilationSucceeded = true
                }
            }

            if !compilationSucceeded && fileManager.fileExists(atPath: dviFilePath) {
                dviDate = fileModificationDate(atPath: dviFilePath)
                if let dviDate, let texDate, (dviDate as NSDate).isNewerThan(texDate as NSDate) {
                    requireDviDriver = true
                    compilationSucceeded = true
                }
            }

            if !compilationSucceeded {
                controller?.showExecError("LaTeX")
                return false
            }

            if requireDviDriver {
                success = execDviDriver(dviFilePath)
                if !success {
                    if ignoreErrorsFlag {
                        errorsIgnored = true
                    } else {
                        controller?.showExecError("DVI driver")
                        return false
                    }
                }
                controller?.exitCurrentThreadIfTaskKilled()

                compilationSucceeded = false
                requireGS = false

                if fileManager.fileExists(atPath: pdfFilePath) {
                    pdfDate = fileModificationDate(atPath: pdfFilePath)
                    if let pdfDate, let texDate, (pdfDate as NSDate).isNewerThan(texDate as NSDate) {
                        requireGS = false
                        compilationSucceeded = true
                    }
                }

                if !compilationSucceeded && fileManager.fileExists(atPath: psFilePath) {
                    psDate = fileModificationDate(atPath: psFilePath)
                    if let psDate, let dviDate, (psDate as NSDate).isNewerThan(dviDate as NSDate) {
                        requireGS = true
                        compilationSucceeded = true
                    }
                }

                if !compilationSucceeded {
                    controller?.showExecError("DVI driver")
                    return false
                }
            }
        }

        if psInputMode || requireGS {
            success = ps2pdf(psFilePath, outputFile: pdfFilePath)
            if !success {
                if ignoreErrorsFlag {
                    errorsIgnored = true
                } else {
                    return false
                }
            }
            controller?.exitCurrentThreadIfTaskKilled()

            compilationSucceeded = false

            if fileManager.fileExists(atPath: pdfFilePath) {
                pdfDate = fileModificationDate(atPath: pdfFilePath)
                if let pdfDate, let psDate, (pdfDate as NSDate).isNewerThan(psDate as NSDate) {
                    compilationSucceeded = true
                }
            }

            if !compilationSucceeded {
                controller?.showExecError("Ghostscript")
                return false
            }
        }

        controller?.exitCurrentThreadIfTaskKilled()

        guard let pdfDocument = PDFDocument(filePath: pdfFilePath) else {
            controller?.showFileFormatError(pdfFilePath)
            return false
        }

        pageCount = pdfDocument.pageCount

        emptyPageFlags = []
        for i in 1...pageCount {
            var pageSuccess = true
            let isEmpty = willEmptyPageBeCreated(pdfFilePath, page: UInt(i), success: &pageSuccess)
            if !pageSuccess { return false }
            emptyPageFlags.append(NSNumber(value: isEmpty))
        }

        whitePageFlags = []
        for i in 1...pageCount {
            var pageSuccess = true
            let isWhite = isEmptyPage(pdfFilePath, page: UInt(i), success: &pageSuccess)
            if !pageSuccess { return false }
            let isSkipped = i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue
            whitePageFlags.append(NSNumber(value: isWhite && !isSkipped))
        }

        // PDFから各形式に変換
        if bitmapExtensions.contains(extension_) && speedPriorityMode {
            for i in 1...pageCount {
                success = pdf2image(pdfFilePath,
                                    outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                    page: UInt(i), crop: true)
                controller?.exitCurrentThreadIfTaskKilled()
                if !success { return success }
            }
        } else if extension_ == "pdf" && leaveTextFlag {
            for i in 1...pageCount {
                success = pdfcrop(pdfFilePath,
                                  outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                  page: UInt(i), addMargin: true, useCache: false, fillBackground: !transparentFlag)
                controller?.exitCurrentThreadIfTaskKilled()
                if !success { return success }
            }
        } else if (extension_ == "svg" || extension_ == "svgz") && leaveTextFlag {
            let skippedCount = (emptyPageFlags as NSArray).indexesOfTrueValue().count
            if !(mergeOutputsFlag && (pageCount - skippedCount > 1)) {
                if transparentFlag {
                    _ = pdfcrop(pdfFilePath, outputFileName: croppedPdfFilePath, page: 0, addMargin: true, useCache: true, fillBackground: false)
                    controller?.exitCurrentThreadIfTaskKilled()

                    for i in 1...pageCount {
                        success = pdf2svg(croppedPdfFilePath,
                                          outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                          page: UInt(i), skipEmptyPage: true)
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                } else {
                    _ = pdfcrop(pdfFilePath, outputFileName: croppedPdfFilePath, page: 1, addMargin: true, useCache: false, fillBackground: true)
                    controller?.exitCurrentThreadIfTaskKilled()

                    for i in 1...pageCount {
                        _ = pdfcrop(pdfFilePath,
                                    outputFileName: (croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                    page: UInt(i), addMargin: true, useCache: false, fillBackground: true)
                        controller?.exitCurrentThreadIfTaskKilled()

                        success = pdf2svg((croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                          outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                          page: 1, skipEmptyPage: false)
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                }
            }
        } else {
            if transparentFlag || bitmapExtensions.contains(extension_) {
                if extension_ == "svg" || extension_ == "svgz" {
                    for i in 1...pageCount {
                        if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }
                        success = convertPDF(pdfFileName,
                                             toOutlinedSVG: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             page: UInt(i))
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                } else if isUsingNewGS() {
                    if extension_ == "eps" {
                        for i in 1...pageCount {
                            if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }
                            let croppedFile = (croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i))
                            _ = pdfcrop(pdfFilePath, outputFileName: croppedFile, page: UInt(i), addMargin: false, useCache: false, fillBackground: false)
                            controller?.exitCurrentThreadIfTaskKilled()

                            success = convertPDF((croppedFile as NSString).lastPathComponent,
                                                 intermediateOutlinedFileName: (outputEpsFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 page: 1, useCache: false, skipEmptyPage: false)
                            controller?.exitCurrentThreadIfTaskKilled()
                            if !success { return success }
                        }
                    } else {
                        for i in 1...pageCount {
                            success = convertPDF(pdfFileName,
                                                 intermediateOutlinedFileName: (outputEpsFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 page: UInt(i), useCache: true, skipEmptyPage: true)
                            controller?.exitCurrentThreadIfTaskKilled()
                            if !success { return success }
                        }
                    }
                } else {
                    for i in 1...pageCount {
                        if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }
                        let croppedFile = (croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i))
                        _ = pdfcrop(pdfFilePath, outputFileName: croppedFile, page: UInt(i), addMargin: false, useCache: false, fillBackground: false)
                        controller?.exitCurrentThreadIfTaskKilled()

                        success = convertPDF((croppedFile as NSString).lastPathComponent,
                                             intermediateOutlinedFileName: (outputEpsFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             page: 1, useCache: false, skipEmptyPage: false)
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                }
            } else {
                if extension_ == "eps" {
                    for i in 1...pageCount {
                        if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }
                        let croppedFile = (croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i))
                        _ = pdfcrop(pdfFilePath, outputFileName: croppedFile, page: UInt(i), addMargin: true, useCache: false, fillBackground: true)
                        controller?.exitCurrentThreadIfTaskKilled()

                        success = convertPDF((croppedFile as NSString).lastPathComponent,
                                             intermediateOutlinedFileName: (outputEpsFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             page: 1, useCache: false, skipEmptyPage: false)
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                } else if extension_ == "pdf" {
                    for i in 1...pageCount {
                        if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }

                        if i <= whitePageFlags.count && whitePageFlags[i - 1].boolValue {
                            _ = pdfcrop(pdfFilePath,
                                        outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                        page: UInt(i), addMargin: true, useCache: false, fillBackground: !transparentFlag)
                        } else {
                            _ = pdfcrop(pdfFilePath,
                                        outputFileName: (croppedPdfFilePath as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                        page: UInt(i), addMargin: false, useCache: false, fillBackground: false)
                            controller?.exitCurrentThreadIfTaskKilled()

                            success = convertPDF(((croppedPdfFilePath as NSString).lastPathComponent as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 intermediateOutlinedFileName: (outputEpsFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 outputFileName: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                                 page: 1, useCache: false, skipEmptyPage: false)
                            controller?.exitCurrentThreadIfTaskKilled()
                            if !success { return success }
                        }
                    }
                } else if extension_ == "svg" || extension_ == "svgz" {
                    for i in 1...pageCount {
                        if i <= emptyPageFlags.count && emptyPageFlags[i - 1].boolValue { continue }
                        success = convertPDF(pdfFileName,
                                             toOutlinedSVG: (outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)),
                                             page: UInt(i))
                        controller?.exitCurrentThreadIfTaskKilled()
                        if !success { return success }
                    }
                }
            }
        }

        if mergeableExtensions.contains(extension_) && mergeOutputsFlag {
            var outputFiles = [String]()
            for i in 1...pageCount {
                if i <= emptyPageFlags.count && !emptyPageFlags[i - 1].boolValue {
                    outputFiles.append((workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i))))
                }
            }

            if !outputFiles.isEmpty {
                if fileManager.isDirectory(atPath: outputFilePath) {
                    controller?.showCannotOverwriteError(outputFilePath)
                    return false
                }

                if outputFiles.count > 1 {
                    controller?.appendOutputAndScroll(String(format: "TeX2img: Merging %@s...\n\n", extension_.uppercased()), quiet: quietFlag)
                }

                if extension_ == "pdf" {
                    if outputFiles.count > 1 {
                        let tempOutPath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName + "-out.pdf")
                        try? fileManager.removeItem(atPath: tempOutPath)
                        success = PDFDocument(merging: outputFiles)?.writeToFilePath(tempOutPath) ?? false
                        if success {
                            success = copyTarget(from: tempOutPath, toPath: outputFilePath)
                        }
                    } else {
                        success = copyTarget(from: outputFiles[0], toPath: outputFilePath)
                    }
                    if !success { return false }
                }

                if extension_ == "tiff" {
                    if outputFiles.count > 1 {
                        success = mergeTIFFFiles(outputFiles, toPath: outputFilePath)
                    } else {
                        success = copyTarget(from: outputFiles[0], toPath: outputFilePath)
                    }
                    if !success { return false }
                }

                if extension_ == "gif" {
                    if outputFiles.count > 1 {
                        success = generateAnimatedGIF(from: outputFiles, toPath: outputFilePath)
                    } else {
                        success = copyTarget(from: outputFiles[0], toPath: outputFilePath)
                    }
                    if !success { return false }
                }

                if extension_ == "svg" || extension_ == "svgz" {
                    if outputFiles.count > 1 {
                        if extension_ == "svgz" {
                            let newSvgPath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName + "-merge.svg")
                            success = generateAnimatedSVG(from: outputFiles, toPath: newSvgPath)
                            if success {
                                success = gzipSVG(newSvgPath, toSVGZ: outputFilePath)
                            }
                        } else {
                            success = generateAnimatedSVG(from: outputFiles, toPath: outputFilePath)
                        }
                    } else if extension_ == "svgz" {
                        success = gzipSVG(outputFiles[0], toSVGZ: outputFilePath)
                    } else {
                        success = copyTarget(from: outputFiles[0], toPath: outputFilePath)
                    }
                    if !success { return false }
                }

                if success {
                    embedTeXSource(texFilePath, intoFile: outputFilePath)
                }

                if copyToClipboard {
                    let pboard = NSPasteboard.general
                    pboard.declareTypes([.fileURL], owner: nil)
                    pboard.clearContents()
                    pboard.writeObjects([NSURL(fileURLWithPath: outputFilePath)])
                }
            }
        } else {
            var destURLs = [NSURL]()

            for i in 1...pageCount {
                if i <= emptyPageFlags.count && !emptyPageFlags[i - 1].boolValue {
                    let destPath = (outputFilePath as NSString).pathStringByAppendingPageNumber(UInt(i))
                    destURLs.append(NSURL(fileURLWithPath: destPath))

                    let origPath = (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i)))
                    if extension_ == "svgz" {
                        success = gzipSVG(origPath, toSVGZ: destPath)
                    } else {
                        success = copyTarget(from: origPath, toPath: destPath)
                    }

                    if success {
                        embedTeXSource(texFilePath, intoFile: destPath)
                    } else {
                        return false
                    }
                }
            }

            if copyToClipboard && !destURLs.isEmpty {
                let pboard = NSPasteboard.general
                pboard.declareTypes([.fileURL], owner: nil)
                pboard.clearContents()
                pboard.writeObjects(destURLs)
            }
        }

        return true
    }
    @objc private func runAppleScriptOnMainThread(_ script: String) {
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    private func compileAndConvertWithCheck() -> Bool {
        guard controller?.latexExists(atPath: (latexPath as NSString).programPath,
                                      dviDriverPath: (dviDriverPath as NSString).programPath,
                                      gsPath: (gsPath as NSString).programPath) == true else {
            controller?.generationDidFinish(.failed)
            return false
        }

        let extension_ = (outputFilePath as NSString).pathExtension.lowercased()


        if !targetExtensions.contains(extension_) {
            controller?.showExtensionError()
            controller?.generationDidFinish(.failed)
            return false
        }

        controller?.prepareOutputTextView()
        if showOutputWindowFlag {
            controller?.showOutputWindow()
        }
        controller?.showMainWindow()

        let status = compileAndConvert()
        controller?.releaseOutputTextView()

        if !status {
            controller?.generationDidFinish(.failed)
            return false
        }

        var generatedFiles = [String]()
        let skippedIndexes = (emptyPageFlags as NSArray).indexesOfTrueValue()
        let generatedPageCount = pageCount - skippedIndexes.count
        if mergeableExtensions.contains(extension_) && mergeOutputsFlag && generatedPageCount > 0 {
            generatedFiles.append(outputFilePath)
        } else {
            for i in 1...pageCount {
                if i <= emptyPageFlags.count && !emptyPageFlags[i - 1].boolValue {
                    generatedFiles.append((outputFilePath as NSString).pathStringByAppendingPageNumber(UInt(i)))
                }
            }
        }

        if status && previewFlag {
            let previewApp: String
            if extension_ == "gif" && mergeOutputsFlag && generatedPageCount > 1 {
                previewApp = fileManager.fileExists(atPath: "/System/Applications/Safari.app") ? "/System/Applications/Safari.app" : "/Applications/Safari.app"
            } else if extension_ == "svgz" {
                previewApp = SVG_PREVIEWER
            } else if extension_ == "svg" {
                if fileManager.fileExists(atPath: SVG_PREVIEWER) {
                    previewApp = SVG_PREVIEWER
                } else if fileManager.fileExists(atPath: "/System/Applications/Safari.app") {
                    previewApp = "/System/Applications/Safari.app"
                } else {
                    previewApp = "/Applications/Safari.app"
                }
            } else {
                previewApp = fileManager.fileExists(atPath: "/System/Applications/Preview.app") ? "/System/Applications/Preview.app" : "/Applications/Preview.app"
            }

            let pathsForPreview = generatedFiles.map { path -> String in
                if #available(macOS 13, *) {
                    if extension_ == "eps" {
                        let pdfPathForPreview = (fileManager.temporaryDirectory.path as NSString).appendingPathComponent(((path as NSString).lastPathComponent as NSString).deletingPathExtension + ".pdf")
                        _ = epstopdf(path, outputFileName: pdfPathForPreview)
                        return pdfPathForPreview
                    }
                }
                return path
            }

            controller?.previewFiles(pathsForPreview, withApplication: previewApp)
        }

        if status && copyToClipboard && autoPasteFlag && autoPasteDestination != 0 && !generatedFiles.isEmpty {
            var script: String?
            switch autoPasteDestination {
            case 1:
                script = appleScriptForWord(generatedFiles)
            case 2:
                script = appleScriptForPowerPoint(generatedFiles)
            case 3:
                script = appleScriptForiWork("Pages")
            case 4:
                script = appleScriptForiWork("Numbers")
            case 5:
                script = appleScriptForiWork("Keynote")
            default:
                break
            }

            if let script {
                performSelector(onMainThread: #selector(runAppleScriptOnMainThread(_:)), with: script, waitUntilDone: false)
            }
        }

        if status && embedInIllustratorFlag && !generatedFiles.isEmpty {
            var script = "tell application \"Adobe Illustrator\"\nactivate\n"
            for filePath in generatedFiles {
                script += String(format: "embed (make new placed item in current document with properties {file path:(POSIX file \"%@\")})\n", filePath)
                if ungroupFlag {
                    script += "move page items of selection of current document to end of current document\n"
                }
            }
            script += "end tell\n"
            performSelector(onMainThread: #selector(runAppleScriptOnMainThread(_:)), with: script, waitUntilDone: false)
        }

        if status {
            controller?.printResult(generatedFiles, quiet: quietFlag)
        }

        let skippedPageIndexes = (emptyPageFlags as NSArray).indexesOfTrueValue()
        if skippedPageIndexes.count > 0 {
            controller?.showPageSkippedWarning((skippedPageIndexes as NSIndexSet).arrayOfIndexesPlusOne as [NSNumber])
        }

        let whitePageIndexes = (whitePageFlags as NSArray).indexesOfTrueValue()
        if status && whitePageIndexes.count > 0 {
            controller?.showWhitePageWarning((whitePageIndexes as NSIndexSet).arrayOfIndexesPlusOne as [NSNumber])
        }

        if ignoreErrorsFlag && errorsIgnored {
            controller?.showErrorsIgnoredWarning()
        }

        deleteTemporaryFiles()

        let exitStatus: ExitStatus = status ? .succeeded : .failed
        controller?.generationDidFinish(exitStatus)
        return status
    }

    func deleteTemporaryFiles() {
        guard deleteTmpFileFlag else { return }

        let outputFileName = (outputFilePath as NSString).lastPathComponent
        let basePath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName)
        let extension_ = (outputFilePath as NSString).pathExtension.lowercased()

        let tempFiles = [
            "\(basePath).tex", "\(basePath).dvi", "\(basePath).log", "\(basePath).aux", "\(basePath).ps",
            "\(basePath).pdf", "\(basePath)-crop.pdf", "\(basePath)-image.pdf", "\(basePath)-outline.pdf",
            "\(basePath).eps", "\(basePath)-trim.pdf", "\(basePath)-pdftops.pdf", "\(basePath)-pdftops.eps",
            "\(basePath)-pdfcrop-00.pdf", "\(basePath)-pdfcrop-01.pdf", "\(basePath)-out.\(extension_)"
        ]

        for path in tempFiles {
            try? fileManager.removeItem(atPath: path)
        }

        if extension_ == "svgz" {
            try? fileManager.removeItem(atPath: "\(basePath)-out.svg")
            try? fileManager.removeItem(atPath: "\(basePath)-merge.svg")
            try? fileManager.removeItem(atPath: (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).stringByReplacingPathExtension("svg")))
        }

        let outputDir = (outputFilePath as NSString).deletingLastPathComponent
        for i in 1...pageCount {
            let outputFullPath = Utility.getFullPath(outputDir) ?? outputDir
            let workingFullPath = Utility.getFullPath(workingDirectory) ?? workingDirectory

            if outputFullPath != workingFullPath {
                try? fileManager.removeItem(atPath: (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i))))
            } else if mergeableExtensions.contains((outputFilePath as NSString).pathExtension) && mergeOutputsFlag && i >= 2 {
                try? fileManager.removeItem(atPath: (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).pathStringByAppendingPageNumber(UInt(i))))
            }

            let pageTempFiles = [
                String(format: "%@-crop-%ld.pdf", basePath, i),
                String(format: "%@-%ld.eps", basePath, i),
                String(format: "%@-%ld-outline.pdf", basePath, i),
                String(format: "%@-%ld-crop.pdf", basePath, i),
                String(format: "%@-%ld-trim.pdf", basePath, i),
                String(format: "%@-%ld-pdftops.eps", basePath, i),
                String(format: "%@-%ld-pdftops.pdf", basePath, i)
            ]
            for path in pageTempFiles {
                try? fileManager.removeItem(atPath: path)
            }

            if extension_ == "svgz" {
                let svgPath = (workingDirectory as NSString).appendingPathComponent((outputFileName as NSString).stringByReplacingPathExtension("svg"))
                try? fileManager.removeItem(atPath: (svgPath as NSString).pathStringByAppendingPageNumber(UInt(i)))
            }
        }

        let auxFiles = ["bbl", "bcf", "blg", "fls", "idx", "ind", "ilg", "out", "toc", "synctex", "synctex.gz"]
        for ext in auxFiles {
            try? fileManager.removeItem(atPath: "\(basePath).\(ext)")
        }
        try? fileManager.removeItem(atPath: "\(basePath)-blx.bib")
        try? fileManager.removeItem(atPath: "\(basePath).run.xml")
        try? fileManager.removeItem(atPath: "\(basePath).synctex.gz(busy)")
    }

    @objc(compileAndConvertWithSource:)
    func compileAndConvert(withSource texSourceStr: String) -> Bool {
        let tempTeXFilePath = String(format: "%@.tex", (workingDirectory as NSString).appendingPathComponent(tempFileBaseName))

        if !writeStringWithYenBackslashConverting(texSourceStr, toFile: tempTeXFilePath) {
            controller?.showFileGenerationError(tempTeXFilePath)
            controller?.generationDidFinish(.failed)
            return false
        }

        return compileAndConvertWithCheck()
    }

    @objc(compileAndConvertWithBody:)
    func compileAndConvert(withBody texBodyStr: String) -> Bool {
        autoreleasepool {
            let texSourceStr = String(format: "%@\n\\begin{document}\n%@\n\\end{document}", preambleStr, texBodyStr)
            return compileAndConvert(withSource: texSourceStr)
        }
    }

    @objc(compileAndConvertWithInputPath:)
    func compileAndConvert(withInputPath sourcePath: String) -> Bool {
        autoreleasepool {
            additionalInputPath = (Utility.getFullPath(sourcePath) as NSString?)?.deletingLastPathComponent
            if workingDirectoryType == Int(WorkingDirectoryFile) {
                workingDirectory = additionalInputPath ?? workingDirectory
            }

            if fileManager.isDirectory(atPath: sourcePath) {
                controller?.showFileFormatError(sourcePath)
                controller?.generationDidFinish(.failed)
                return false
            }

            let ext = (sourcePath as NSString).pathExtension.lowercased()
            pdfInputMode = ext == "pdf"
            psInputMode = ext == "ps" || ext == "eps"
            let basePath = (workingDirectory as NSString).appendingPathComponent(tempFileBaseName)

            if pdfInputMode {
                guard PDFDocument(filePath: sourcePath) != nil else {
                    controller?.showFileFormatError(sourcePath)
                    controller?.generationDidFinish(.failed)
                    return false
                }

                let tempPdfFilePath = (basePath as NSString).appendingPathExtension("pdf")!
                guard (try? fileManager.copyItem(atPath: sourcePath, toPath: tempPdfFilePath)) != nil else {
                    controller?.showFileGenerationError(tempPdfFilePath)
                    controller?.generationDidFinish(.failed)
                    return false
                }
            } else if psInputMode {
                let tempPsFilePath = (basePath as NSString).appendingPathExtension("ps")!
                guard (try? fileManager.copyItem(atPath: sourcePath, toPath: tempPsFilePath)) != nil else {
                    controller?.showFileGenerationError(tempPsFilePath)
                    controller?.generationDidFinish(.failed)
                    return false
                }
            } else {
                let tempTeXFilePath = (basePath as NSString).appendingPathExtension("tex")!
                guard (try? fileManager.copyItem(atPath: sourcePath, toPath: tempTeXFilePath)) != nil else {
                    controller?.showFileGenerationError(tempTeXFilePath)
                    controller?.generationDidFinish(.failed)
                    return false
                }
            }

            return compileAndConvertWithCheck()
        }
    }

    private func appleScriptForWord(_ paths: [String]) -> String {
        var script = """
        tell application "Microsoft Word"
        activate
        if version < 15 then
        tell selection
        set myStart to selection start
        set myEnd to selection end
        end tell
        tell active document
        set theRange to create range start myStart end myEnd
        """

        for posixPath in paths.reversed() {
            script += String(format: "make new inline picture at theRange with properties {file name:(POSIX file \"%@\") as Unicode text, save with document:true}\n", posixPath)
        }

        script += """
        end tell
        else
        tell active document
        tell application "System Events" to (keystroke "v" using command down)
        end tell
        end if
        end tell
        """
        return script
    }

    private func appleScriptForPowerPoint(_ paths: [String]) -> String {
        var script = """
        tell application "Microsoft PowerPoint"
        activate
        if version < 15 then
        set thisSlide to slide index of slide of view of active window
        tell slide thisSlide of active presentation
        """

        for posixPath in paths {
            script += String(format: "set thePicture to make new picture at end with properties {file name:(POSIX file \"%@\") as Unicode text, save with document:true}\n", posixPath)
            script += """
            tell thePicture
            scale height factor 1 scale scale from top left with relative to original size
            scale width factor 1 scale scale from top left with relative to original size
            end tell
            """
        }

        script += """
        end tell
        else
        tell active presentation
        tell application "System Events" to (keystroke "v" using command down)
        end tell
        end if
        end tell
        """
        return script
    }

    private func appleScriptForiWork(_ appName: String) -> String {
        return """
        tell application "\(appName)"
        activate
        tell document
        tell application "System Events" to (keystroke "v" using command down)
        end tell
        end tell
        """
    }
}