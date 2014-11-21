#import <Cocoa/Cocoa.h>
#import "Converter.h"
#import "ProfileController.h"
#import "TeXTextView.h"
#import "global.h"

typedef enum  {
	FLASH, SOLID, NOHIGHLIGHT
} HighlightPattern;

@class ProfileController;
@class TeXTextView;

@interface ControllerG : NSObject<OutputController> {
	IBOutlet ProfileController *profileController;
    IBOutlet NSWindow *mainWindow;
    IBOutlet TeXTextView *sourceTextView;
	IBOutlet NSDrawer *outputDrawer;
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSWindow *preambleWindow;
    IBOutlet TeXTextView *preambleTextView;
	IBOutlet NSMenuItem *convertYenMarkMenuItem;
	IBOutlet NSMenuItem *colorizeTextMenuItem;
	IBOutlet NSMenuItem *outputDrawerMenuItem;
	IBOutlet NSMenuItem *preambleWindowMenuItem;
	IBOutlet NSMenuItem *generateMenuItem;
	IBOutlet NSMenuItem *flashHighlightMenuItem;
	IBOutlet NSMenuItem *solidHighlightMenuItem;
	IBOutlet NSMenuItem *noHighlightMenuItem;
	IBOutlet NSMenuItem *flashInMovingMenuItem;
	IBOutlet NSMenuItem *highlightContentMenuItem;
	IBOutlet NSMenuItem *beepMenuItem;
	IBOutlet NSMenuItem *flashBackgroundMenuItem;
	IBOutlet NSMenuItem *checkBraceMenuItem;
	IBOutlet NSMenuItem *checkBracketMenuItem;
	IBOutlet NSMenuItem *checkSquareBracketMenuItem;
	IBOutlet NSMenuItem *checkParenMenuItem;
	IBOutlet NSMenuItem *autoCompleteMenuItem;
	IBOutlet NSMenuItem *showTabCharacterMenuItem;
	IBOutlet NSMenuItem *showSpaceCharacterMenuItem;
	IBOutlet NSMenuItem *showNewLineCharacterMenuItem;
	IBOutlet NSMenuItem *showFullwidthSpaceCharacterMenuItem;
	IBOutlet NSTextField *outputFileTextField;
	IBOutlet NSButton *generateButton;
	IBOutlet NSButton *transparentCheckBox;
	IBOutlet NSButton *showOutputDrawerCheckBox;
	IBOutlet NSButton *threadingCheckBox;
	IBOutlet NSButton *previewCheckBox;
	IBOutlet NSButton *deleteTmpFileCheckBox;
	IBOutlet NSWindow *preferenceWindow;
	IBOutlet NSTextField *resolutionLabel;
	IBOutlet NSTextField *leftMarginLabel;
	IBOutlet NSTextField *rightMarginLabel;
	IBOutlet NSTextField *topMarginLabel;
	IBOutlet NSTextField *bottomMarginLabel;
	IBOutlet NSSlider *resolutionSlider;
	IBOutlet NSSlider *leftMarginSlider;
	IBOutlet NSSlider *rightMarginSlider;
	IBOutlet NSSlider *topMarginSlider;
	IBOutlet NSSlider *bottomMarginSlider;
	IBOutlet NSTextField *platexPathTextField;
	IBOutlet NSTextField *dvipdfmxPathTextField;
	IBOutlet NSTextField *gsPathTextField;
	IBOutlet NSButton *getOutlineCheckBox;
	IBOutlet NSButton *ignoreErrorCheckBox;
	IBOutlet NSButton *utfExportCheckBox;
	IBOutlet NSButtonCell *sjisRadioButton;
	IBOutlet NSButtonCell *eucRadioButton;
	IBOutlet NSButtonCell *jisRadioButton;
	IBOutlet NSButtonCell *utf8RadioButton;
	IBOutlet NSButtonCell *upTeXRadioButton;
	
	HighlightPattern highlightPattern;
}
- (IBAction)generate:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)toggleOutputDrawer:(id)sender;
- (IBAction)togglePreambleWindow:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)toggleMenuItem:(id)sender;
- (IBAction)changeHighlight:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)showProfilesWindow:(id)sender;
- (IBAction)showSavePanel:(id)sender;
- (IBAction)restoreDefaultPreamble:(id)sender;
- (IBAction)openTempDir:(id)sender;
- (IBAction)showFontPanelOfSource:(id)sender;
- (IBAction)showFontPanelOfPreamble:(id)sender;
- (IBAction)searchPrograms:(id)sender;
- (IBAction)setParametersForTeXLive:(id)sender;
- (void)adoptProfile:(NSDictionary*)aProfile;
- (NSMutableDictionary*)currentProfile;
@end
