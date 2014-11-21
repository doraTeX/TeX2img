#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
@class ControllerG;

@interface TeXTextView : NSTextView {
	IBOutlet ControllerG *controller;
}
- (void)colorizeText:(BOOL)colorize;
@end
