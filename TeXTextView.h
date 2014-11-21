#import <Cocoa/Cocoa.h>
#import "ControllerG.h"
#import "global.h"

@class ControllerG;

@interface TeXTextView : NSTextView
{
    IBOutlet ControllerG *controller;
    BOOL autoCompleting;
    BOOL contentHighlighting;
    BOOL braceHighlighting;
    NSDictionary* highlightBracesColorDict;
    NSUInteger lastCursorLocation;
    NSUInteger lastStringLength;
    NSDictionary* autocompletionDictionary;
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