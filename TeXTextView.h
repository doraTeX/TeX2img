#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface TeXTextView : NSTextView {
	IBOutlet ControllerG *controller;
	NSDictionary* highlightBracesColorDict;
	int lastCursorLocation;
	int lastStringLength;
	NSDictionary* autocompletionDictionary;
	BOOL autoCompleting;
	BOOL contentHighlighting;
	BOOL braceHighlighting;
}
@end

@interface TeXTextView (Colorize)
- (void)colorizeText:(BOOL)colorize;
- (void)resetBackgroundColor:(id)sender;
@end

@interface TeXTextView (CommandCompletion)
- (IBAction) doNextBullet: (id)sender;
- (IBAction) doPreviousBullet: (id)sender;
@end