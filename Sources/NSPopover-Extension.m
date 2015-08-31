#import "NSPopover-Extension.h"

@implementation NSPopover (Extension)
+ (instancetype)popoverWithContentViewController:(NSViewController*)controller
{
    NSPopover *popover = [NSPopover new];
    popover.contentViewController = controller;
    popover.behavior = NSPopoverBehaviorTransient;
    return popover;
}

- (void)showAtRightOfButton:(NSButton*)button
                     ofView:(NSView*)view
                    offsetX:(CGFloat)x
                          Y:(CGFloat)y
{
    NSRect rect = button.frame;
    rect = NSMakeRect(rect.origin.x + x, rect.origin.y + y, rect.size.width, rect.size.height);
    
    [self showRelativeToRect:rect ofView:view preferredEdge:NSMaxXEdge];
}

+ (void)showPopoverWithViewController:(NSViewController*)controller
                      atRightOfButton:(NSButton*)button
                               ofView:(NSView*)view
                              offsetX:(CGFloat)x
                                    Y:(CGFloat)y
{
    [[NSPopover popoverWithContentViewController:controller] showAtRightOfButton:button
                                                                          ofView:view
                                                                         offsetX:x
                                                                               Y:y];
}

@end
