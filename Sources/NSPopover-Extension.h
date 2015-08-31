#import <Foundation/Foundation.h>

@interface NSPopover (Extension)
+ (instancetype)popoverWithContentViewController:(NSViewController*)controller;
- (void)showAtRightOfButton:(NSButton*)button
                     ofView:(NSView*)view
                    offsetX:(CGFloat)x
                          Y:(CGFloat)y;
+ (void)showPopoverWithViewController:(NSViewController*)controller
                      atRightOfButton:(NSButton*)button
                               ofView:(NSView*)view
                              offsetX:(CGFloat)x
                                    Y:(CGFloat)y;
@end
