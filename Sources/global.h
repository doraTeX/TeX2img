#ifndef TeX2img_global_h
#define TeX2img_global_h

#import "typedef.h"
typedef enum {
	apWord = 1,
    apPowerPoint = 2,
    apPages = 3,
    apNumbers = 4,
    apKeynote = 5
} AutoPasteDestination;

typedef NSDictionary<NSString*,id> Profile;
typedef NSMutableDictionary<NSString*,id> MutableProfile;

#define AnnotationHeader @"%%TeX2img Document\n"

#define BASH_PATH @"/bin/bash"
#define CUI_PATH @"/usr/local/bin/tex2img"
#define SVG_PREVIEWER @"/Applications/Gapplin.app"
#define GAPPLIN_URL @"macappstore://apps.apple.com/app/id768053424?mt=12"

#define TargetExtensionsArray (@[@"eps", @"pdf", @"svg", @"svgz", @"jpg", @"png", @"gif", @"tiff", @"bmp"])
#define ImportExtensionsArray (@[@"eps", @"pdf", @"svg", @"svgz", @"jpg", @"png", @"gif", @"tiff", @"bmp", @"tex"])
#define InputExtensionsArray (@[@"tex", @"pdf", @"ps", @"eps"])
#define BitmapExtensionsArray (@[@"png", @"jpg", @"gif", @"tiff", @"bmp"])
#define MergeableExtensionsArray (@[@"pdf", @"tiff", @"gif", @"svg", @"svgz"])

#define ProfileNamesKey @"profileNames"
#define ProfilesKey @"profiles"

#define XKey @"x"
#define YKey @"y"
#define MainWindowWidthKey @"mainWindowWidth"
#define MainWindowHeightKey @"mainWindowHeight"
#define OutputFileKey @"outputFile"
#define ShowOutputWindowKey @"showOutputDrawer"
#define ThreadingKey @"threading"
#define SendNotificationKey @"sendNotification"
#define PreviewKey @"preview"
#define DeleteTmpFileKey @"deleteTmpFile"
#define CopyToClipboardKey @"copyToClipboard"
#define AutoPasteKey @"autoPaste"
#define AutoPasteDestinationKey @"autoPasteDestination"
#define EmbedInIllustratorKey @"embedInIllustrator"
#define UngroupKey @"ungroup"
#define TransparentKey @"transparent"
#define PlainTextKey @"plainText"
#define GetOutlineKey @"getOutline"
#define DeleteDisplaySizeKey @"deleteDisplaySize"
#define MergeOutputsKey @"mergeOutputs"
#define KeepPageSizeKey @"keepPageSize"
#define IgnoreErrorKey @"ignoreError"
#define UtfExportKey @"utfExport"
#define LatexPathKey @"platexPath"
// DviDriverPathKey の内容は，互換性を考えて "dvipdfmxPath" のままで維持
#define DviDriverPathKey @"dvipdfmxPath"
#define GsPathKey @"gsPath"
#define GuessCompilationKey @"guessCompilation"
#define NumberOfCompilationKey @"numberOfCompilation"
#define ResolutionKey @"resolution"
#define DPIKey @"dpi"
#define LeftMarginKey @"leftMargin"
#define RightMarginKey @"rightMargin"
#define TopMarginKey @"topMargin"
#define BottomMarginKey @"bottomMargin"
#define UnitKey @"unit"
#define PriorityKey @"priority"
#define EmbedSourceKey @"embedSource"
#define TabWidthKey @"tabWidth"
#define TabIndentKey @"tabIndent"
#define WrapLineKey @"warpLines"

#define CommandCompletionKeyKey @"commandCompletionKey"

#define FillColorKey @"fillColor"

#define ForegroundColorForLightModeKey @"foregroundColor"
#define BackgroundColorForLightModeKey @"backgroundColor"
#define CursorColorForLightModeKey @"cursorColor"
#define BraceColorForLightModeKey @"braceColor"
#define CommentColorForLightModeKey @"commentColor"
#define CommandColorForLightModeKey @"commandColor"
#define InvisibleColorForLightModeKey @"invisibleColor"
#define HighlightedBraceColorForLightModeKey @"highlightedBraceColor"
#define EnclosedContentBackgroundColorForLightModeKey @"enclosedContentBackgroundColor"
#define FlashingBackgroundColorForLightModeKey @"flashingBackgroundColor"
#define ConsoleForegroundColorForLightModeKey @"consoleForegroundColor"
#define ConsoleBackgroundColorForLightModeKey @"consoleBackgroundColor"

#define ForegroundColorForDarkModeKey @"foregroundColorForDarkMode"
#define BackgroundColorForDarkModeKey @"backgroundColorForDarkMode"
#define CursorColorForDarkModeKey @"cursorColorForDarkMode"
#define BraceColorForDarkModeKey @"braceColorForDarkMode"
#define CommentColorForDarkModeKey @"commentColorForDarkMode"
#define CommandColorForDarkModeKey @"commandColorForDarkMode"
#define InvisibleColorForDarkModeKey @"invisibleColorForDarkMode"
#define HighlightedBraceColorForDarkModeKey @"highlightedBraceColorForDarkMode"
#define EnclosedContentBackgroundColorForDarkModeKey @"enclosedContentBackgroundColorForDarkMode"
#define FlashingBackgroundColorForDarkModeKey @"flashingBackgroundColorForDarkMode"
#define ConsoleForegroundColorForDarkModeKey @"consoleForegroundColorForDarkMode"
#define ConsoleBackgroundColorForDarkModeKey @"consoleBackgroundColorForDarkMode"

#define MakeatletterEnabledKey @"makeatletterEnabled"

#define WorkingDirectoryTypeKey @"workingDirectoryType"
#define WorkingDirectoryPathKey @"workingDirectoryPath"

#define WorkingDirectoryTmp     1
#define WorkingDirectoryFile    2
#define WorkingDirectoryCurrent 3

#define ColorPalleteColorKey @"colorPalleteColor"

#define ConvertYenMarkKey @"convertYenMark"
#define RichTextKey @"copyAsRichText"
#define FlashInMovingKey @"flashInMoving"
#define HighlightContentKey @"highlightContent"
#define BeepKey @"beep"
#define FlashBackgroundKey @"flashBackground"
#define CheckBraceKey @"checkBrace"
#define CheckBracketKey @"checkBracket"
#define CheckSquareBracketKey @"checkSquareBracket"
#define CheckParenKey @"checkParen"
#define AutoCompleteKey @"autoComplete"
#define AutoIndentKey @"autoIndent"
#define ShowTabCharacterKey @"showTabCharacter"
#define ShowSpaceCharacterKey @"showSpaceCharacter"
#define ShowFullwidthSpaceCharacterKey @"showFullwidthSpaceCharacter"
#define ShowNewLineCharacterKey @"showNewLineCharacter"
#define SourceFontNameKey @"sourceFontName"
#define SourceFontSizeKey @"sourceFontSize"
#define PreambleKey @"preamble"
#define SourceBodyKey @"sourceBody"
#define InputMethodKey @"inputMethod"
#define InputSourceFilePathKey @"inputSourceFilePath"
#define EncodingKey @"encoding"
#define EpstopdfPathKey @"epstopdfPath"
#define MudrawPathKey @"mudrawPath"
#define PdftopsPathKey @"pdftopsPath"
#define QuietKey @"quiet"

#define AutoDetectionTargetKey @"autoDetectionTarget"
#define SpaceCharacterKindKey @"spaceCharacterKind"
#define FullwidthSpaceCharacterKindKey @"fullwidthSpaceCharacterKind"
#define ReturnCharacterKindKey @"returnCharacterKind"
#define TabCharacterKindKey @"tabCharacterKind"
#define PageBoxKey @"pageBox"

#define LoopCountKey @"loopCount"
#define DelayKey @"delay"

#define ControllerKey @"controller"
#define TeX2imgVersionKey @"TeX2imgVersion"

#define ESCAPE_KEY 1
#define TAB_KEY 2

#define LIGHTMODE_TAG 1
#define DARKMODE_TAG 2

#define PX_UNIT_TAG 1
#define BP_UNIT_TAG 2
#define QUALITY_PRIORITY_TAG 1
#define SPEED_PRIORITY_TAG 2
#define DIRECT_INPUT_TAG 0
#define INPUT_FILE_TAG 1

#define COLOR_TAG 1
#define TEXTCOLOR_TAG 2
#define COLORBOX_TAG 3
#define DEFINECOLOR_TAG 4

#define CommentOutTag 1
#define UncommentTag 2
#define ShiftRightTag 3
#define ShiftLeftTag 4

#define NFC_Tag 1
#define Modified_NFC_Tag 2
#define NFD_Tag 3
#define Modified_NFD_Tag 4
#define NFKC_Tag 5
#define NFKD_Tag 6
#define NFKC_CF_Tag 7

#define HiraganaToKatakana_Tag 1
#define KatakanaToHiragana_Tag 2
#define FullwidthDigitsToHalfwidthDigits_Tag 3
#define HalfwidthDigitsToFullwidthDigits_Tag 4
#define FullwidthAlphabetsToHalfwidthAlphabets_Tag 5
#define HalfwidthAlphabetsToFullwidthAlphabets_Tag 6
#define UnicodeCharactersToAJMacros_Tag 7
#define AJMacrosToUnicodeCharacters_Tag 8
#define UnicodeCharactersToUTF_Tag 9
#define UTFToUnicodeCharacters_Tag 10
#define FullwidthQuotesToHalfwidthQuotes_Tag 11

#define TeXtoDVItoPDF 1
#define TeXtoPDF 2

#define PTEX_ENCODING_NONE @"none"
#define PTEX_ENCODING_UTF8 @"utf8"
#define PTEX_ENCODING_SJIS @"sjis"
#define PTEX_ENCODING_JIS @"jis"
#define PTEX_ENCODING_EUC @"euc"

#define EA_Key "com.loveinequality.TeX2img"

#define GUI_PATHS (@[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"], [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"], NSHomeDirectory(), @"/Applications", @"/Applications/TeXLive"])

#endif
