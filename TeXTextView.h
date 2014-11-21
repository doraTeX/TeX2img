#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface TeXTextView : NSTextView {
	IBOutlet ControllerG *controller;
	NSDictionary* highlightBracesColorDict;
	int _lastCursorLocation;
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