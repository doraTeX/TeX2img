#import "NSMatrix-Extension.h"

@implementation NSMatrix (Extension)
- (void)setCellColor:(NSColor*)color
{
    [(NSArray<NSButtonCell*>*)(self.cells) enumerateObjectsUsingBlock:^(NSButtonCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
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
    [(NSArray<NSButtonCell*>*)(self.cells) enumerateObjectsUsingBlock:^(NSButtonCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableAttributedString *title =
        [[NSMutableAttributedString alloc] initWithAttributedString:cell.attributedTitle];
        
        [title addAttribute:NSFontAttributeName
                      value:font
                      range:NSMakeRange(0, title.length)];
        
        cell.attributedTitle = title;
    }];
}

@end
