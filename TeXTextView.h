#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface TeXTextView : NSTextView {
	IBOutlet ControllerG *controller;
	NSDictionary* highlightBracesColorDict;
	int _lastCursorLocation;
}
- (void)colorizeText:(BOOL)colorize;
@end
