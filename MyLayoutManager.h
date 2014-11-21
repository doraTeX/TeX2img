#import <Cocoa/Cocoa.h>
#import "ControllerG.h"

@interface MyLayoutManager : NSLayoutManager {
    NSString *tabCharacter;
    NSString *newLineCharacter;
    NSString *fullwidthSpaceCharacter;
    NSString *spaceCharacter;
	ControllerG *controller;
}
- (void)setController:(ControllerG*)aController;
@end

