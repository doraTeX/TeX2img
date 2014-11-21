#import <Cocoa/Cocoa.h>
#import "Converter.h"
#import "ProfileController.h"
@class ProfileController;

@interface ControllerG : NSObject<OutputController> {
	IBOutlet ProfileController *profileController;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSTextView *sourceTextView;
    IBOutlet NSWindow *outputWindow;
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSWindow *preambleWindow;
    IBOutlet NSTextView *preambleTextView;
	IBOutlet NSMenuItem *convertYenMarkMenuItem;
	IBOutlet NSMenuItem *outputWindowMenuItem;
	IBOutlet NSMenuItem *preambleWindowMenuItem;
	IBOutlet NSTextField *outputFileTextField;
	IBOutlet NSButton *transparentCheckBox;
	IBOutlet NSButton *showOutputWindowCheckBox;
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
	
	
}
- (IBAction)generate:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)toggleOutputWindow:(id)sender;
- (IBAction)togglePreambleWindow:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)toggleMenuItem:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)showProfilesWindow:(id)sender;
- (IBAction)showSavePanel:(id)sender;
- (IBAction)restoreDefaultPreamble:(id)sender;
- (IBAction)openTempDir:(id)sender;
- (IBAction)showFontPanelOfSource:(id)sender;
- (IBAction)showFontPanelOfPreamble:(id)sender;
- (IBAction)searchPrograms:(id)sender;
- (void)adoptProfile:(NSDictionary*)aProfile;
- (NSMutableDictionary*)currentProfile;
@end
