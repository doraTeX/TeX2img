#import <Foundation/Foundation.h>

#ifndef typedef_h
#define typedef_h

typedef NS_ENUM(NSInteger, ExitStatus) {
    ExitStatusSucceeded = 0,
    ExitStatusFailed = 1,
    ExitStatusAborted = 2
};

#endif /* typedef_h */
