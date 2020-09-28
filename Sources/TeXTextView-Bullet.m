#import "TeXTextView.h"

#pragma mark - Control bullets (from TeXShop)

NSString *placeholderString = @"\u2022"; // "•"
NSString *startCommentString = @"\u2022\u2039"; // "•‹"
NSString *endCommentString = @"\u203A"; // "›"

@implementation TeXTextView (Bullet)
- (IBAction)doNextBullet:(id)sender // modified by (HS)
{
    NSString *text = self.string;
    NSRange tempRange = self.selectedRange;
    tempRange.location += tempRange.length; // move the range to after the selection (a la Find) to avoid re-finding (HS)
    //set up a search range from here to eof
    NSRange forwardRange = NSMakeRange(tempRange.location, text.length - tempRange.location);
    NSRange markerRange = [text rangeOfString:placeholderString options:NSLiteralSearch range:forwardRange];

    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound) { // marker found
        NSRange commentRange = NSMakeRange(markerRange.location, text.length - markerRange.location);
        commentRange = [text rangeOfString:startCommentString options:NSLiteralSearch range:commentRange];

        if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)) {
            // found comment start right after marker --- there is a comment
            commentRange.location = markerRange.location;
            commentRange.length = text.length - markerRange.location;
            commentRange = [text rangeOfString:endCommentString options:NSLiteralSearch range:commentRange];

            if (commentRange.location != NSNotFound) {
                markerRange.length = commentRange.location - markerRange.location + commentRange.length;
            }
        }

        self.selectedRange = markerRange;
        [self scrollRangeToVisible:markerRange];

    } else {
        NSBeep();
    }
}

- (IBAction)doPreviousBullet:(id)sender // modified by (HS)
{
    NSString *text = self.string;
    NSRange tempRange = self.selectedRange;
    //set up a search range from string start to beginning of selection
    NSRange backwardRange = NSMakeRange(0, tempRange.location);
    NSRange markerRange = [text rangeOfString:placeholderString options:NSBackwardsSearch range:backwardRange];

    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound) { // marker found
        NSRange commentRange = NSMakeRange(markerRange.location, text.length - markerRange.location);
        commentRange = [text rangeOfString:startCommentString options:NSLiteralSearch range:commentRange];

        if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)) {
            // found comment start right after marker --- there is a comment
            commentRange.location = markerRange.location;
            commentRange.length = text.length - markerRange.location;
            commentRange = [text rangeOfString:endCommentString options:NSLiteralSearch range:commentRange];

            if (commentRange.location != NSNotFound) {
                markerRange.length = commentRange.location - markerRange.location + commentRange.length;
            }
        }

        self.selectedRange = markerRange;
        [self scrollRangeToVisible:markerRange];

    } else {
        NSBeep();
    }
}

- (IBAction)doNextBulletAndDelete:(id)sender // modified by (HS)
{
    NSString *text = self.string;
    NSRange tempRange = self.selectedRange;
    tempRange.location += tempRange.length; // move the range to after the selection (a la Find) to avoid re-finding (HS)
    //set up a search range from here to eof
    NSRange forwardRange = NSMakeRange(tempRange.location, text.length - tempRange.location);
    NSRange markerRange = [text rangeOfString:placeholderString options:NSLiteralSearch range:forwardRange];
    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound) { // marker found
        NSRange commentRange = NSMakeRange(markerRange.location, text.length - markerRange.location);
        commentRange = [text rangeOfString:startCommentString options:NSLiteralSearch range:commentRange];

        if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)) {
            // found comment start right after marker --- there is a comment
            commentRange.location = markerRange.location;
            commentRange.length = text.length - markerRange.location;
            commentRange = [text rangeOfString:endCommentString options:NSLiteralSearch range:commentRange];

            if (commentRange.location != NSNotFound) {
                markerRange.length = commentRange.location - markerRange.location + commentRange.length;
            }
        }

        // delete bullet (marker)
        tempRange.location = markerRange.location;
        tempRange.length = placeholderString.length;
        markerRange.length -= tempRange.length; // deleting the bullet so selection is shorter
        [self replaceCharactersInRange:tempRange withString:@""];

        // end delete bullet (marker)
        self.selectedRange = markerRange;
        [self scrollRangeToVisible:markerRange];

    } else {
        NSBeep();
    }
}

- (IBAction)doPreviousBulletAndDelete:(id)sender // modified by (HS)
{
    NSString *text = self.string;
    NSRange tempRange = self.selectedRange;
    //set up a search range from string start to beginning of selection
    NSRange backwardRange = NSMakeRange(0, tempRange.location);
    NSRange markerRange = [text rangeOfString:placeholderString options:NSBackwardsSearch range:backwardRange];

    //if marker found - set commentRange there and look for end of comment
    if (markerRange.location != NSNotFound) { // marker found
        NSRange commentRange = NSMakeRange(markerRange.location, text.length - markerRange.location);
        commentRange = [text rangeOfString:startCommentString options:NSLiteralSearch range:commentRange];

        if ((commentRange.location != NSNotFound) && (commentRange.location == markerRange.location)) {
            // found comment start right after marker --- there is a comment
            NSRange commentRange = NSMakeRange(markerRange.location, text.length - markerRange.location);
            commentRange = [text rangeOfString:endCommentString options:NSLiteralSearch range:commentRange];

            if (commentRange.location != NSNotFound) {
                markerRange.length = commentRange.location - markerRange.location + commentRange.length;
            }
        }
        
        // delete bullet (marker)
        tempRange.location = markerRange.location;
        tempRange.length = placeholderString.length;
        markerRange.length -= tempRange.length; // deleting the bullet so selection is shorter
        [self replaceCharactersInRange:tempRange withString:@""];
        
        // end delete bullet (marker)
        self.selectedRange = markerRange;
        [self scrollRangeToVisible:markerRange];

    } else {
        NSBeep();
    }
}

- (IBAction)placeBullet:(id)sender // modified by (HS) to be a simple insertion (replacing the selection)
{
    NSRange myRange = self.selectedRange;
    [self replaceCharactersInRange:myRange withString:placeholderString] ;//" •\n" puts • on previous line
    myRange.location += placeholderString.length; //= end+2;//start puts • on previous line
    myRange.length = 0;
    self.selectedRange = myRange;
}

- (IBAction)placeComment:(id)sender // by (HS) to be a simple insertion (replacing the selection)
{
    NSRange myRange = self.selectedRange;
    [self replaceCharactersInRange:myRange withString:startCommentString]; //" •\n" puts • on previous line
    myRange.location += startCommentString.length; //= end+2;//start puts • on previous line
    myRange.length = 0;
    [self replaceCharactersInRange:myRange withString:endCommentString];
    self.selectedRange = myRange;
}
@end
