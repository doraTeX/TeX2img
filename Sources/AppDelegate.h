#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject<NSApplicationDelegate>
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
@end
