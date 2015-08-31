#import "NSMatrix-Extension.h"

@implementation NSMatrix (Extension)
- (void)setCellColor:(NSColor*)color
{
    [self.cells enumerateObjectsUsingBlock:^(NSButtonCell *cell, NSUInteger idx, BOOL *stop) {
        NSMutableAttributedString *title =
        [[NSMutableAttributedString alloc] initWithAttributedString:cell.attributedTitle];
        
        [title addAttribute:NSForegroundColorAttributeName
                      value:color
                      range:NSMakeRange(0, title.length)];
        
        cell.attributedTitle = title;
    }];
}

- (void)setCellFont:(NSFont*)font
{
    [self.cells enumerateObjectsUsingBlock:^(NSButtonCell *cell, NSUInteger idx, BOOL *stop) {
        NSMutableAttributedString *title =
        [[NSMutableAttributedString alloc] initWithAttributedString:cell.attributedTitle];
        
        [title addAttribute:NSFontAttributeName
                      value:font
                      range:NSMakeRange(0, title.length)];
        
        cell.attributedTitle = title;
    }];
}

@end
