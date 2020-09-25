#import <Cocoa/Cocoa.h>
#import "ControllerG.h"

@class ControllerG;

@interface TeXTextView : NSTextView
{
    IBOutlet ControllerG *controller;
    BOOL autoCompleting;
    BOOL contentHighlighting;
    BOOL braceHighlighting;
    NSDictionary<NSString*,id> *highlightBracesColorDict;
    NSUInteger lastCursorLocation;
    NSUInteger lastStringLength;
    NSDictionary<NSString*,NSString*> *autocompletionDictionary;
    BOOL dragging;
    NSDragOperation currentDragOperation;
}
- (BOOL)isValidTeXCommandChar:(unichar)c;
- (void)registerUndoWithString:(NSString*)oldString
                      location:(NSUInteger)oldLocation
                        length:(NSUInteger)newLength
                           key:(NSString*)key;
- (void)setEnabled:(BOOL)enabled;
- (void)replaceEntireContentsWithString:(NSString*)contents;
- (void)insertTextWithIndicator:(id)aString;
- (void)fixupTabs;
- (void)refreshWordWrap;
- (NSString*)indentStringForCurrentLocation;
@property (nonatomic, assign) id<DnDDelegate> dropDelegate;
@end

@interface TeXTextView (Colorize)
- (void)colorizeText;
- (void)resetBackgroundColor:(id)sender;
@end

@interface TeXTextView (Bullet)
- (void)doNextBullet:(id)sender;
- (void)doPreviousBullet:(id)sender;
- (void)doNextBulletAndDelete:(id)sender;
- (void)doPreviousBulletAndDelete:(id)sender;
- (void)placeBullet:(id)sender;
- (void)placeComment:(id)sender;
@end
