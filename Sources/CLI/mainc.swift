import AppKit
import ArgumentParser
import Foundation
import Quartz

let tex2imgVersion = "2.4.3"

private let defaultMaximalNumberOfCompilation = 3
private let enabledStatus = "enabled"
private let disabledStatus = "disabled"
private let inputExtensions = ["tex", "pdf", "ps", "eps"]

private enum Tex2imgCLIError: Error {
    case usage
    case failed
}

@main
struct Tex2imgCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tex2img",
        abstract: "Convert TeX/PDF/PS/EPS files to image formats.",
        helpNames: []
    )

    // MARK: - Conversion Settings

    @Option(name: [.customLong("latex"), .customLong("compiler")], help: "LaTeX compiler (default: platex)")
    var latex = "platex"

    @Option(name: .customLong("kanji"), help: "Japanese encoding (no|utf8|sjis|jis|euc)")
    var kanji: String?

    @Flag(name: .customLong("guess-compile"))
    var guessCompile = false

    @Flag(name: .customLong("no-guess-compile"))
    var noGuessCompile = false

    @Option(name: .customLong("num"), help: "Maximal number of compilation")
    var num: Int?

    @Option(name: [.customLong("dvidriver"), .customLong("dviware"), .customLong("dvipdfmx")], help: "DVI driver (default: dvipdfmx)")
    var dviDriver = "dvipdfmx"

    @Option(name: .customLong("gs"), help: "Ghostscript (default: gs)")
    var gs = "gs"

    @Flag(name: .customLong("ignore-errors"))
    var ignoreErrors = false

    @Flag(name: .customLong("no-ignore-errors"))
    var noIgnoreErrors = false

    @Flag(name: .customLong("utf-export"))
    var utfExport = false

    @Flag(name: .customLong("no-utf-export"))
    var noUtfExport = false

    @Flag(name: .customLong("quick"))
    var quick = false

    @Flag(name: .customLong("no-quick"))
    var noQuick = false

    @Option(name: .customLong("workingdir"), help: "Working directory (tmp|file|current)")
    var workingDir: String?

    // MARK: - Image Settings

    @Option(name: .customLong("resolution"), help: "Resolution level (default: 15)")
    var resolution: Float = 15

    @Option(name: .customLong("dpi"), help: "DPI for bitmap images (default: 72)")
    var dpi: Int = 72

    @Option(name: .customLong("margins"), help: "Margins (1, 2, or 4 values)")
    var margins: String?

    @Option(name: .customLong("left-margin"), help: "Left margin (default: 0)")
    var leftMarginOption: Int?

    @Option(name: .customLong("right-margin"), help: "Right margin (default: 0)")
    var rightMarginOption: Int?

    @Option(name: .customLong("top-margin"), help: "Top margin (default: 0)")
    var topMarginOption: Int?

    @Option(name: .customLong("bottom-margin"), help: "Bottom margin (default: 0)")
    var bottomMarginOption: Int?

    @Option(name: .customLong("unit"), help: "Margin unit (px|bp)")
    var unit: String?

    @Flag(name: .customLong("keep-page-size"))
    var keepPageSize = false

    @Flag(name: .customLong("no-keep-page-size"))
    var noKeepPageSize = false

    @Option(name: .customLong("pagebox"), help: "Page box type (media|crop|bleed|trim|art)")
    var pagebox: String?

    @Flag(name: .customLong("transparent"))
    var transparent = false

    @Flag(name: .customLong("no-transparent"))
    var noTransparent = false

    @Option(name: .customLong("background-color"), help: "Background color")
    var backgroundColor: String?

    // MARK: - Format-specific Settings

    @Flag(name: .customLong("with-text"))
    var withText = false

    @Flag(name: .customLong("no-with-text"))
    var noWithText = false

    @Flag(name: .customLong("plain-text"))
    var plainText = false

    @Flag(name: .customLong("no-plain-text"))
    var noPlainText = false

    @Flag(name: .customLong("merge-output-files"))
    var mergeOutputFiles = false

    @Flag(name: .customLong("no-merge-output-files"))
    var noMergeOutputFiles = false

    @Option(name: .customLong("animation-delay"), help: "Animation delay in seconds")
    var animationDelay: Float?

    @Option(name: .customLong("animation-loop"), help: "Animation loop count (0 = infinity)")
    var animationLoop: Int?

    @Flag(name: .customLong("delete-display-size"))
    var deleteDisplaySize = false

    @Flag(name: .customLong("no-delete-display-size"))
    var noDeleteDisplaySize = false

    // MARK: - Behavior

    @Flag(name: .customLong("preview"))
    var preview = false

    @Flag(name: .customLong("no-preview"))
    var noPreview = false

    @Flag(name: .customLong("delete-tmpfiles"))
    var deleteTmpfiles = false

    @Flag(name: .customLong("no-delete-tmpfiles"))
    var noDeleteTmpfiles = false

    @Flag(name: .customLong("embed-source"))
    var embedSource = false

    @Flag(name: .customLong("no-embed-source"))
    var noEmbedSource = false

    @Flag(name: .customLong("copy-to-clipboard"))
    var copyToClipboard = false

    @Flag(name: .customLong("no-copy-to-clipboard"))
    var noCopyToClipboard = false

    // MARK: - Other

    @Flag(name: .customLong("quiet"))
    var quiet = false

    @Flag(name: .customLong("no-quiet"))
    var noQuiet = false

    @Flag(name: .customLong("version"))
    var showVersion = false

    @Flag(name: .customLong("help"))
    var showHelp = false

    @Argument(help: "Input file path")
    var inputFile: String?

    @Argument(help: "Output file path")
    var outputFile: String?

    mutating func run() throws {
        if showVersion {
            printVersion()
            throw ExitCode.success
        }

        if showHelp {
            printUsage()
            throw ExitCode(1)
        }

        guard let inputFile, let outputFile else {
            printUsage()
            throw ExitCode(1)
        }

        do {
            let exitCode = try execute(inputFile: inputFile, outputFile: outputFile)
            throw ExitCode(exitCode)
        } catch let error as Tex2imgCLIError {
            switch error {
            case .usage:
                printUsage()
                throw ExitCode(1)
            case .failed:
                throw ExitCode.failure
            }
        }
    }

    private mutating func execute(inputFile: String, outputFile: String) throws -> Int32 {
        _ = NSApplication.shared

        let quietFlag = resolveFlag(positive: "quiet", negative: "no-quiet",
                                    positiveSet: quiet, negativeSet: noQuiet, defaultValue: false)

        if !quietFlag {
            printVersion()
        }

        guard FileManager.default.fileExists(atPath: inputFile) else {
            UtilityC.printStdErr("tex2img : No such file or directory - \(inputFile)\n")
            throw Tex2imgCLIError.failed
        }

        let inputExtension = inputFile.pathExtension
        guard inputExtensions.contains(inputExtension) else {
            UtilityC.printStdErr("tex2img : Invalid input file type - \(inputFile)\n")
            throw Tex2imgCLIError.failed
        }

        var leftMargin = leftMarginOption ?? 0
        var rightMargin = rightMarginOption ?? 0
        var topMargin = topMarginOption ?? 0
        var bottomMargin = bottomMarginOption ?? 0

        if let margins {
            try applyMargins(margins, left: &leftMargin, right: &rightMargin, top: &topMargin, bottom: &bottomMargin)
        }

        guard leftMargin >= 0, rightMargin >= 0, topMargin >= 0, bottomMargin >= 0 else {
            UtilityC.printStdErr("tex2img : Margins must not be negative.\n")
            throw Tex2imgCLIError.failed
        }

        let encoding = try resolveKanjiEncoding()
        let unitTag = try resolveUnitTag()
        let pageBoxType = try resolvePageBoxType()
        let workingDirectoryType = try resolveWorkingDirectoryType()

        var numberOfCompilation = num
        let guessFlag = resolveFlag(positive: "guess-compile", negative: "no-guess-compile",
                                    positiveSet: guessCompile, negativeSet: noGuessCompile, defaultValue: true)
        if numberOfCompilation == nil {
            numberOfCompilation = guessFlag ? defaultMaximalNumberOfCompilation : 1
        }

        var transparentFlag = resolveFlag(positive: "transparent", negative: "no-transparent",
                                          positiveSet: transparent, negativeSet: noTransparent, defaultValue: true)
        var fillColor = NSColor.white

        if let backgroundColor {
            transparentFlag = false
            fillColor = try parseBackgroundColor(backgroundColor)
        }

        let delay = animationDelay ?? 1
        if delay < 0 {
            print("error: --animation-delay is invalid.\n")
            throw Tex2imgCLIError.failed
        }

        let loopCount = animationLoop ?? 0
        if loopCount < 0 {
            print("error: --animation-loop is invalid.\n")
            throw Tex2imgCLIError.failed
        }

        let controller = ControllerC()
        guard let latexPath = UtilityC.getPath(latex.programPath) else {
            controller.showNotFoundError(latex.programName)
            UtilityC.suggestLatexOption()
            throw Tex2imgCLIError.failed
        }
        guard let dviDriverPath = UtilityC.getPath(dviDriver.programPath) else {
            controller.showNotFoundError(dviDriver.programName)
            throw Tex2imgCLIError.failed
        }
        guard let gsPath = UtilityC.getPath(gs.programPath) else {
            controller.showNotFoundError(gs.programName)
            throw Tex2imgCLIError.failed
        }
        guard let epstopdfPath = UtilityC.getPath("epstopdf") else {
            controller.showNotFoundError("epstopdf")
            throw Tex2imgCLIError.failed
        }

        var mudrawPath = UtilityC.getPath("mudraw") ?? "mudraw"
        var pdftopsPath = UtilityC.getPath("xpdf-pdftops") ?? UtilityC.getPath("pdftops") ?? "pdftops"

        guard let outputFilePath = Utility.getFullPath(outputFile) else {
            throw Tex2imgCLIError.failed
        }

        var profile: Profile = [:]
        profile[LatexPathKey] = latexPath.appendingStringSeparatedBySpace(latex.argumentsString)
        profile[DviDriverPathKey] = dviDriverPath.appendingStringSeparatedBySpace(dviDriver.argumentsString)
        profile[GsPathKey] = gsPath.appendingStringSeparatedBySpace(gs.argumentsString)
        profile[EpstopdfPathKey] = epstopdfPath
        profile[MudrawPathKey] = mudrawPath
        profile[PdftopsPathKey] = pdftopsPath
        profile[OutputFileKey] = outputFilePath
        profile[EncodingKey] = encoding
        profile[NumberOfCompilationKey] = numberOfCompilation!
        profile[ResolutionKey] = resolution
        profile[DPIKey] = dpi
        profile[LeftMarginKey] = leftMargin
        profile[RightMarginKey] = rightMargin
        profile[TopMarginKey] = topMargin
        profile[BottomMarginKey] = bottomMargin

        let textPdfFlag = resolveFlag(positive: "with-text", negative: "no-with-text",
                                      positiveSet: withText, negativeSet: noWithText, defaultValue: false)
        profile[GetOutlineKey] = !textPdfFlag
        profile[TransparentKey] = transparentFlag
        profile[FillColorKey] = fillColor.serializedString

        let deleteDisplaySizeFlag = resolveFlag(positive: "delete-display-size", negative: "no-delete-display-size",
                                                positiveSet: deleteDisplaySize, negativeSet: noDeleteDisplaySize, defaultValue: false)
        profile[DeleteDisplaySizeKey] = deleteDisplaySizeFlag
        profile[ShowOutputWindowKey] = false

        let previewFlag = resolveFlag(positive: "preview", negative: "no-preview",
                                      positiveSet: preview, negativeSet: noPreview, defaultValue: false)
        profile[PreviewKey] = previewFlag

        let deleteTmpFileFlag = resolveFlag(positive: "delete-tmpfiles", negative: "no-delete-tmpfiles",
                                            positiveSet: deleteTmpfiles, negativeSet: noDeleteTmpfiles, defaultValue: true)
        profile[DeleteTmpFileKey] = deleteTmpFileFlag
        profile[AutoPasteKey] = false
        profile[AutoPasteDestinationKey] = 0
        profile[EmbedInIllustratorKey] = false
        profile[UngroupKey] = false

        let ignoreErrorFlag = resolveFlag(positive: "ignore-errors", negative: "no-ignore-errors",
                                          positiveSet: ignoreErrors, negativeSet: noIgnoreErrors, defaultValue: false)
        profile[IgnoreErrorKey] = ignoreErrorFlag

        let utfExportFlag = resolveFlag(positive: "utf-export", negative: "no-utf-export",
                                        positiveSet: utfExport, negativeSet: noUtfExport, defaultValue: false)
        profile[UtfExportKey] = utfExportFlag
        profile[QuietKey] = quietFlag
        profile[GuessCompilationKey] = guessFlag
        profile[ControllerKey] = controller
        profile[UnitKey] = unitTag

        let quickFlag = resolveFlag(positive: "quick", negative: "no-quick",
                                    positiveSet: quick, negativeSet: noQuick, defaultValue: false)
        profile[PriorityKey] = quickFlag ? Int(SPEED_PRIORITY_TAG) : Int(QUALITY_PRIORITY_TAG)

        let copyToClipboardFlag = resolveFlag(positive: "copy-to-clipboard", negative: "no-copy-to-clipboard",
                                              positiveSet: copyToClipboard, negativeSet: noCopyToClipboard, defaultValue: false)
        profile[CopyToClipboardKey] = copyToClipboardFlag

        let embedSourceFlag = resolveFlag(positive: "embed-source", negative: "no-embed-source",
                                          positiveSet: embedSource, negativeSet: noEmbedSource, defaultValue: true)
        profile[EmbedSourceKey] = embedSourceFlag

        let mergeFlag = resolveFlag(positive: "merge-output-files", negative: "no-merge-output-files",
                                    positiveSet: mergeOutputFiles, negativeSet: noMergeOutputFiles, defaultValue: false)
        profile[MergeOutputsKey] = mergeFlag

        let keepPageSizeFlag = resolveFlag(positive: "keep-page-size", negative: "no-keep-page-size",
                                           positiveSet: keepPageSize, negativeSet: noKeepPageSize, defaultValue: false)
        profile[KeepPageSizeKey] = keepPageSizeFlag

        let plainTextFlag = resolveFlag(positive: "plain-text", negative: "no-plain-text",
                                        positiveSet: plainText, negativeSet: noPlainText, defaultValue: false)
        profile[PlainTextKey] = plainTextFlag
        profile[PageBoxKey] = pageBoxType
        profile[LoopCountKey] = loopCount
        profile[DelayKey] = delay
        profile[WorkingDirectoryTypeKey] = workingDirectoryType
        profile[WorkingDirectoryPathKey] = workingDirectoryType == Int(WorkingDirectoryCurrent)
            ? FileManager.default.currentDirectoryPath
            : ""

        if !quietFlag {
            printCurrentStatus(inputFilePath: inputFile, profile: profile)
        }

        let converter = Converter(profile: profile)
        let success = converter.compileAndConvert(withInputPath: inputFile)
        return success ? Int32(ExitStatus.succeeded.rawValue) : Int32(ExitStatus.failed.rawValue)
    }

    private func resolveKanjiEncoding() throws -> String {
        guard let kanji else { return PTEX_ENCODING_NONE }

        if kanji == "no" {
            return PTEX_ENCODING_NONE
        }
        if kanji == PTEX_ENCODING_UTF8 || kanji == PTEX_ENCODING_SJIS
            || kanji == PTEX_ENCODING_JIS || kanji == PTEX_ENCODING_EUC {
            return kanji
        }

        print("error: --kanji is invalid. It must be no/utf8/sjis/jis/euc.\n")
        throw Tex2imgCLIError.failed
    }

    private func resolveUnitTag() throws -> Int {
        guard let unit else { return Int(PX_UNIT_TAG) }

        if unit == "px" {
            return Int(PX_UNIT_TAG)
        }
        if unit == "bp" {
            return Int(BP_UNIT_TAG)
        }

        print("error: --unit is invalid. It must be \"px\" or \"bp\".\n")
        throw Tex2imgCLIError.failed
    }

    private func resolvePageBoxType() throws -> CGPDFBox {
        guard let pagebox else { return CGPDFBox.cropBox }

        switch pagebox {
        case "media":
            return .mediaBox
        case "crop":
            return .cropBox
        case "bleed":
            return .bleedBox
        case "trim":
            return .trimBox
        case "art":
            return .artBox
        default:
            print("error: --pagebox is invalid. It must be media/crop/bleed/trim/art.\n")
            throw Tex2imgCLIError.failed
        }
    }

    private func resolveWorkingDirectoryType() throws -> Int {
        guard let workingDir else { return Int(WorkingDirectoryTmp) }

        switch workingDir {
        case "tmp":
            return Int(WorkingDirectoryTmp)
        case "file":
            return Int(WorkingDirectoryFile)
        case "current":
            return Int(WorkingDirectoryCurrent)
        default:
            print("error: --workingdir is invalid. It must be tmp/file/current.\n")
            throw Tex2imgCLIError.failed
        }
    }

    private func applyMargins(_ marginsString: String,
                              left: inout Int,
                              right: inout Int,
                              top: inout Int,
                              bottom: inout Int) throws {
        let values = marginsString
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        switch values.count {
        case 1:
            let value = try parseInteger(values[0])
            left = value
            right = value
            top = value
            bottom = value
        case 2:
            left = try parseInteger(values[0])
            right = left
            top = try parseInteger(values[1])
            bottom = top
        case 4:
            left = try parseInteger(values[0])
            top = try parseInteger(values[1])
            right = try parseInteger(values[2])
            bottom = try parseInteger(values[3])
        default:
            print("error: The number of \"--margins\" values must be 1, 2 or 4.\n")
            throw Tex2imgCLIError.failed
        }
    }

    private func parseBackgroundColor(_ colorString: String) throws -> NSColor {
        let values = colorString
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        switch values.count {
        case 1:
            let colorValue = values[0].lowercased()
            let hexPattern = #"^#?([0-9a-f]{6}|[0-9a-f]{3})$"#
            if let regex = try? NSRegularExpression(pattern: hexPattern),
               let match = regex.firstMatch(in: colorValue, range: NSRange(colorValue.startIndex..., in: colorValue)),
               let hexRange = Range(match.range(at: 1), in: colorValue) {
                let hex = String(colorValue[hexRange])
                var result: UInt32 = 0
                Scanner(string: hex).scanHexInt32(&result)

                let r: Int
                let g: Int
                let b: Int
                if hex.count == 6 {
                    r = Int(result >> 16)
                    result -= UInt32(r << 16)
                    g = Int(result >> 8)
                    b = Int(result - UInt32(g << 8))
                } else {
                    r = Int(result >> 8)
                    result -= UInt32(r << 8)
                    g = Int(result >> 4)
                    b = Int(result - UInt32(g << 4))
                    let expandedR = (r << 4) + r
                    let expandedG = (g << 4) + g
                    let expandedB = (b << 4) + b
                    return NSColor(deviceRed: CGFloat(expandedR) / 255,
                                   green: CGFloat(expandedG) / 255,
                                   blue: CGFloat(expandedB) / 255,
                                   alpha: 1.0)
                }
                return NSColor(deviceRed: CGFloat(r) / 255,
                               green: CGFloat(g) / 255,
                               blue: CGFloat(b) / 255,
                               alpha: 1.0)
            }

            guard let color = NSColor(cssName: colorValue) else {
                print("error: --background-color is invalid.\n")
                throw Tex2imgCLIError.failed
            }
            return color

        case 3:
            let rgb = values.joined()
            let regex = try? NSRegularExpression(pattern: #"^\d+$"#, options: .caseInsensitive)
            let range = NSRange(rgb.startIndex..., in: rgb)
            guard regex?.firstMatch(in: rgb, range: range) != nil else {
                print("error: --background-color is invalid.\n")
                throw Tex2imgCLIError.failed
            }

            let r = Int(values[0]) ?? -1
            let g = Int(values[1]) ?? -1
            let b = Int(values[2]) ?? -1
            guard r >= 0, g >= 0, b >= 0, r <= 255, g <= 255, b <= 255 else {
                print("error: --background-color is invalid. Each RGB value must be less than 256.\n")
                throw Tex2imgCLIError.failed
            }
            return NSColor(deviceRed: CGFloat(r) / 255,
                           green: CGFloat(g) / 255,
                           blue: CGFloat(b) / 255,
                           alpha: 1.0)

        default:
            print("error: The number of --background-color values must be 1 or 3.\n")
            throw Tex2imgCLIError.failed
        }
    }

    private func resolveFlag(positive: String,
                             negative: String,
                             positiveSet: Bool,
                             negativeSet: Bool,
                             defaultValue: Bool) -> Bool {
        if positiveSet && negativeSet {
            let args = CommandLine.arguments
            var lastPositive = -1
            var lastNegative = -1
            for (index, arg) in args.enumerated() {
                if arg == "--\(positive)" {
                    lastPositive = index
                }
                if arg == "--\(negative)" {
                    lastNegative = index
                }
            }
            return lastPositive > lastNegative
        }
        if positiveSet { return true }
        if negativeSet { return false }
        return defaultValue
    }
}

// MARK: - Integer Parsing

private func parseInteger(_ string: String) throws -> Int {
    guard !string.isEmpty else {
        UtilityC.printStdErr("error : Not a number.\n")
        throw Tex2imgCLIError.failed
    }

    var value = 0
    let scanner = Scanner(string: string)
    guard scanner.scanInt(&value), scanner.isAtEnd else {
        UtilityC.printStdErr("error : \(string) is not a number.\n")
        throw Tex2imgCLIError.failed
    }

    return value
}

// MARK: - Output

private func printVersion() {
    print("tex2img Ver.\(tex2imgVersion)")
}

private func printUsage() {
    printVersion()
    print("Usage: tex2img [options] InputFile OutputFile")
    print("")
    print("Arguments:")
    print("  InputFile  : path of a TeX source or PDF/PS/EPS file")
    print("  OutputFile : path of an output file")
    print("               (*extension: eps/pdf/svg/svgz/jpg/png/gif/tiff/bmp)")
    print("")
    print("Conversion Settings:")
    print("  --latex      COMPILER      : set the LaTeX compiler (default: platex)")
    print("   *synonym: --compiler")
    print("  --kanji      ENCODING      : set the Japanese encoding (no|utf8|sjis|jis|euc) (default: no)")
    print("  --[no-]guess-compile       : disable/enable guessing the appropriate number of compilation (default: enabled)")
    print("  --num        NUMBER        : set the (maximal) number of compilation")
    print("  --dvidriver  DRIVER        : set the DVI driver    (default: dvipdfmx)")
    print("   *synonym: --dviware, --dvipdfmx")
    print("  --gs         GS            : set ghostscript (default: gs)")
    print("  --[no-]ignore-errors       : disable/enable ignoring nonfatal errors (default: disabled)")
    print("  --[no-]utf-export          : disable/enable substitution of \\UTF / \\CID for non-JIS X 0208 characters (default: disabled)")
    print("  --[no-]quick               : disable/enable speed priority mode (default: disabled)")
    print("  --workingdir DIR           : set the working directory (tmp|file|current) (default: tmp)")
    print("   *DIR values:")
    print("      tmp            : Standard user temporary directory ($TMPDIR)")
    print("      file           : The same directory as the input file")
    print("      current        : Current directory")
    print("")
    print("Image Settings:")
    print("  --resolution RESOLUTION    : set the resolution level (default: 15)")
    print("  --dpi        DPI           : set the DPI value for bitmap images (default: 72)")
    print("  --margins    \"VALUE\"       : set the margins (default: \"0 0 0 0\")")
    print("   *VALUE format:")
    print("      a single value : used for all margins")
    print("      two values     : left/right and top/bottom margins")
    print("      four values    : left, top, right, and bottom margin respectively")
    print("  --left-margin    MARGIN    : set the left margin   (default: 0)")
    print("  --top-margin     MARGIN    : set the top margin    (default: 0)")
    print("  --right-margin   MARGIN    : set the right margin  (default: 0)")
    print("  --bottom-margin  MARGIN    : set the bottom margin (default: 0)")
    print("  --unit UNIT                : set the unit of margins to \"px\" or \"bp\" (default: px)")
    print("                               (*bp is always used for EPS/PDF/SVG/SVGZ)")
    print("  --[no-]keep-page-size      : disable/enable keeping the original page size (default: disabled)")
    print("  --pagebox BOX              : select the page box type used as the page size (media|crop|bleed|trim|art) (default: crop)")
    print("  --[no-]transparent         : disable/enable transparent (if possible) (default: enabled)")
    print("  --background-color COLOR   : set the background color (default: white)")
    print("   *COLOR format examples:")
    print("      magenta     : CSS-style color name")
    print("      FF00FF      : CSS-style 6-digit HEX format")
    print("      F0F         : CSS-style 3-digit HEX format")
    print("      \"255 0 255\" : RGB integers (0..255)")
    print("")
    print("Image Settings (peculiar to image formats):")
    print("  --[no-]with-text           : disable/enable text-embedded PDF/SVG/SVGZ (default: disabled)")
    print("  --[no-]plain-text          : disable/enable outputting EPS as a plain text (default: disabled)")
    print("  --[no-]merge-output-files  : disable/enable merging products as a single file (PDF/TIFF) or an animation GIF/SVG/SVGZ (default: disabled)")
    print("  --animation-delay TIME     : set the delay time (sec) of an animated GIF/SVG/SVGZ (default: 1)")
    print("  --animation-loop  NUMBER   : set the number of times to repeat an animated GIF/SVG/SVGZ (default: 0 (infinity))")
    print("  --[no-]delete-display-size : disable/enable deleting width and height attributes of SVG/SVGZ (default: disabled)")
    print("")
    print("Behavior After Compiling:")
    print("  --[no-]preview             : disable/enable opening products (default: disabled)")
    print("  --[no-]delete-tmpfiles     : disable/enable deleting temporary files (default: enabled)")
    print("  --[no-]embed-source        : disable/enable embedding of the source in products (default: enabled)")
    print("  --[no-]copy-to-clipboard   : disable/enable copying products to the clipboard (default: disabled)")
    print("")
    print("Other Options:")
    print("  --[no-]quiet               : disable/enable quiet mode (default: disabled)")
    print("  --version                  : display version info")
    print("  --help                     : display this message")
}

private func printCurrentStatus(inputFilePath: String, profile: Profile) {
    print("************************************")
    print("  TeX2img settings")
    print("************************************")
    print("Version: \(tex2imgVersion)")
    print("Input  file: \(inputFilePath)")

    let outputFilePath = profile.stringForKey(OutputFileKey) ?? ""
    print("Output file: \(outputFilePath)")

    let latex = profile.stringForKey(LatexPathKey) ?? ""
    let encoding = profile.stringForKey(EncodingKey) ?? PTEX_ENCODING_NONE
    let kanjiSuffix: String
    if encoding == PTEX_ENCODING_NONE {
        kanjiSuffix = ""
    } else {
        kanjiSuffix = " -kanji=\(encoding)"
    }

    let latexPath = UtilityC.getPath(latex.programName) ?? ""
    print("LaTeX compiler: \(latexPath)\(kanjiSuffix) \(latex.argumentsString)")

    print("Auto detection of the number of compilation: ", terminator: "")
    if profile.boolForKey(GuessCompilationKey) {
        print("enabled")
        print("The maximal number of compilation: \(profile.integerForKey(NumberOfCompilationKey))")
    } else {
        print("disabled")
        print("The number of compilation: \(profile.integerForKey(NumberOfCompilationKey))")
    }

    let dviDriver = profile.stringForKey(DviDriverPathKey) ?? ""
    let dviDriverPath = UtilityC.getPath(dviDriver.programName) ?? ""
    print("DVI Driver: \(dviDriverPath) \(dviDriver.argumentsString)")

    let gs = profile.stringForKey(GsPathKey) ?? ""
    let gsPath = UtilityC.getPath(gs.programName) ?? ""
    print("Ghostscript: \(gsPath) \(gs.argumentsString)")

    let epstopdfPath = UtilityC.getPath(profile.stringForKey(EpstopdfPathKey) ?? "") ?? "NOT FOUND"
    print("epstopdf: \(epstopdfPath)")

    let mudrawPath = UtilityC.getPath(profile.stringForKey(MudrawPathKey) ?? "")
    print("mudraw: \(mudrawPath ?? "NOT FOUND")")

    let pdftopsPath = UtilityC.getPath(profile.stringForKey(PdftopsPathKey) ?? "")
    print("pdftops: \(pdftopsPath ?? "NOT FOUND")")

    print("Working directory: ", terminator: "")
    switch profile.integerForKey(WorkingDirectoryTypeKey) {
    case Int(WorkingDirectoryTmp):
        print(FileManager.default.temporaryDirectory.path, terminator: "")
    case Int(WorkingDirectoryFile):
        if let fullPath = Utility.getFullPath(inputFilePath) {
            print(fullPath.deletingLastPathComponent, terminator: "")
        }
    case Int(WorkingDirectoryCurrent):
        print(FileManager.default.currentDirectoryPath, terminator: "")
    default:
        break
    }
    print("")

    print("Resolution level: \(profile.floatForKey(ResolutionKey))")
    print("DPI: \(profile.integerForKey(DPIKey))")

    let ext = outputFilePath.pathExtension
    let unit: String
    if profile.integerForKey(UnitKey) == Int(PX_UNIT_TAG)
        && (ext == "png" || ext == "gif" || ext == "tiff") {
        unit = "px"
    } else {
        unit = "bp"
    }

    print("Left   margin: \(profile.integerForKey(LeftMarginKey))\(unit)")
    print("Top    margin: \(profile.integerForKey(TopMarginKey))\(unit)")
    print("Right  margin: \(profile.integerForKey(RightMarginKey))\(unit)")
    print("Bottom margin: \(profile.integerForKey(BottomMarginKey))\(unit)")

    print("Transparent: \(profile.boolForKey(TransparentKey) ? enabledStatus : disabledStatus)")
    print("Background color: \(profile.colorForKey(FillColorKey)?.descriptionString ?? "")")

    if ext == "pdf" {
        print("Text embedded PDF: \(profile.boolForKey(GetOutlineKey) ? disabledStatus : enabledStatus)")
    }
    if ext == "eps" {
        print("Plain text EPS: \(profile.boolForKey(PlainTextKey) ? enabledStatus : disabledStatus)")
    }
    if ext == "svg" || ext == "svgz" {
        print("Delete width and height attributes of SVG: \(profile.boolForKey(DeleteDisplaySizeKey) ? enabledStatus : disabledStatus)")
    }

    print("Ignore nonfatal errors: \(profile.boolForKey(IgnoreErrorKey) ? enabledStatus : disabledStatus)")
    print("Substitute \\UTF / \\CID for non-JIS X 0208 characters: \(profile.boolForKey(UtfExportKey) ? enabledStatus : disabledStatus)")
    let priority = profile.integerForKey(PriorityKey) == Int(SPEED_PRIORITY_TAG) ? "speed" : "quality"
    print("Conversion mode: \(priority) priority mode")
    print("Preview generated files: \(profile.boolForKey(PreviewKey) ? enabledStatus : disabledStatus)")
    print("Delete temporary files: \(profile.boolForKey(DeleteTmpFileKey) ? enabledStatus : disabledStatus)")
    print("Embed the source in generated files: \(profile.boolForKey(EmbedSourceKey) ? enabledStatus : disabledStatus)")
    print("Copy generated files to the clipboard: \(profile.boolForKey(CopyToClipboardKey) ? enabledStatus : disabledStatus)")
    print("************************************\n")
}