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
    BOOL dragging;
    NSDragOperation currentDragOperation;
}
- (void)registerUndoWithString:(NSString*)oldString location:(unsigned)oldLocation
                        length: (unsigned)newLength key:(NSString*)key;
- (void)setEnabled:(BOOL)enabled;
- (void)replaceEntireContentsWithString:(NSString*)contents;
- (void)insertTextWithIndicator:(id)aString;
- (void)fixupTabs;
- (void)refreshWordWrap;
@property(nonatomic, assign) id<DnDDelegate> dropDelegate;
@end

@interface TeXTextView (Colorize)
- (void)colorizeText;
- (void)resetBackgroundColor:(id)sender;
@end

@interface TeXTextView (CommandCompletion)
- (IBAction) doNextBullet: (id)sender;
- (IBAction) doPreviousBullet: (id)sender;
@end