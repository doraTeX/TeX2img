NSString *g_commandCompletionChar;
NSMutableString *g_commandCompletionList;

#define localizedString(str) (NSLocalizedString(str, nil))

#define ProfileNamesKey @"profileNames"
#define ProfilesKey @"profiles"

#define XKey @"x"
#define YKey @"y"
#define MainWindowWidthKey @"mainWindowWidth"
#define MainWindowHeightKey @"mainWindowHeight"
#define OutputFileKey @"outputFile"
#define ShowOutputDrawerKey @"showOutputDrawer"
#define ThreadingKey @"threading"
#define PreviewKey @"preview"
#define DeleteTmpFileKey @"deleteTmpFile"
#define EmbedInIllustratorKey @"embedInIllustrator"
#define UngroupKey @"ungroup"
#define TransparentKey @"transparent"
#define GetOutlineKey @"getOutline"
#define IgnoreErrorKey @"ignoreError"
#define UtfExportKey @"utfExport"
#define LatexPathKey @"platexPath"
#define DvipdfmxPathKey @"dvipdfmxPath"
#define GsPathKey @"gsPath"
#define GuessCompilationKey @"guessCompilation"
#define NumberOfCompilationKey @"numberOfCompilation"
#define ResolutionLabelKey @"resolutionLabel"
#define LeftMarginLabelKey @"leftMarginLabel"
#define RightMarginLabelKey @"rightMarginLabel"
#define TopMarginLabelKey @"topMarginLabel"
#define BottomMarginLabelKey @"bottomMarginLabel"
#define ResolutionKey @"resolution"
#define LeftMarginKey @"leftMargin"
#define RightMarginKey @"rightMargin"
#define TopMarginKey @"topMargin"
#define BottomMarginKey @"bottomMargin"
#define UnitKey @"unit"
#define PriorityKey @"priority"
#define EmbedSourceKey @"embedSource"

#define ConvertYenMarkKey @"convertYenMark"
#define ColorizeTextKey @"colorizeText"
#define HighlightPatternKey @"highlightPattern"
#define FlashInMovingKey @"flashInMoving"
#define HighlightContentKey @"highlightContent"
#define BeepKey @"beep"
#define FlashBackgroundKey @"flashBackground"
#define CheckBraceKey @"checkBrace"
#define CheckBracketKey @"checkBracket"
#define CheckSquareBracketKey @"checkSquareBracket"
#define CheckParenKey @"checkParen"
#define AutoCompleteKey @"autoComplete"
#define ShowTabCharacterKey @"showTabCharacter"
#define ShowSpaceCharacterKey @"showSpaceCharacter"
#define ShowFullwidthSpaceCharacterKey @"showFullwidthSpaceCharacter"
#define ShowNewLineCharacterKey @"showNewLineCharacter"
#define SourceFontNameKey @"sourceFontName"
#define SourceFontSizeKey @"sourceFontSize"
#define PreambleFontNameKey @"preambleFontName"
#define PreambleFontSizeKey @"preambleFontSize"
#define PreambleKey @"preamble"
#define InputMethodKey @"inputMethod"
#define InputSourceFilePathKey @"inputSourceFilePath"
#define EncodingKey @"encoding"
#define PdfcropPathKey @"pdfcropPath"
#define EpstopdfPathKey @"epstopdfPath"
#define Pdf2svgPathKey @"pdf2svgPath"
#define QuietKey @"quiet"
#define ControllerKey @"controller"
#define TeX2imgVersionKey @"TeX2imgVersion"

#define PXUNITTAG 1
#define BPUNITTAG 2
#define QUALITY_PRIORITY_TAG 1
#define SPEED_PRIORITY_TAG 2
#define DIRECT_INPUT_TAG 0
#define INPUT_FILE_TAG 1

#define COLOR_TAG 1
#define TEXTCOLOR_TAG 2
#define COLORBOX_TAG 3
#define DEFINECOLOR_TAG 4


#define TeXtoDVItoPDF 1
#define TeXtoPDF 2

#define PTEX_ENCODING_NONE @"none"
#define PTEX_ENCODING_UTF8 @"utf8"
#define PTEX_ENCODING_SJIS @"sjis"
#define PTEX_ENCODING_JIS @"jis"
#define PTEX_ENCODING_EUC @"euc"

#define EAKey "com.loveinequality.TeX2img"

#define ADDITIONAL_PATH @"/Applications/TeX2img.app/Contents/Resources/pdf2svg:/Applications/TeXLive/TeX2img.app/Contents/Resources/pdf2svg"

