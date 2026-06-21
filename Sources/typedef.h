#import <Foundation/Foundation.h>

#ifndef typedef_h
#define typedef_h

typedef NS_ENUM(NSInteger, ExitStatus) {
    ExitStatusSucceeded = 0,
    ExitStatusFailed = 1,
    ExitStatusAborted = 2
};

typedef enum {
    FLASH = 0,
    SOLID = 1,
    NOHIGHLIGHT = 2
} HighlightPattern;

@protocol DnDDelegate <NSObject>
- (void)textViewDroppedFile:(id)file;
@end

#endif /* typedef_h */
