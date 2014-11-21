#import <Cocoa/Cocoa.h>
#import "Converter.h"

@interface Controller : NSObject<OutputController> {
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSTextView *sourceTextView;
    IBOutlet NSWindow *outputWindow;
    IBOutlet NSTextView *outputTextView;
    IBOutlet NSWindow *preambleWindow;
    IBOutlet NSTextView *preambleTextView;
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
	
}
- (IBAction)generate:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)toggleOutputWindow:(id)sender;
- (IBAction)togglePreambleWindow:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)toggleMenuItem:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)showSavePanel:(id)sender;
- (IBAction)restoreDefaultPreamble:(id)sender;
- (IBAction)openTempDir:(id)sender;
@end
