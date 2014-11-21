#import "TeXTextView.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"

@implementation TeXTextView
- (void)insertText:(id)aString
{
	if([aString isEqualToString:@"¥"] && [[controller currentProfile] boolForKey:@"convertYenMark"])
	{
		[super insertText:@"\\"];
	}
	else
	{
		[super insertText:aString];
	}
}

// クリップボードから貼り付けられる円マークをバックスラッシュに置き換えて貼り付ける
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	if([type isEqualToString:NSStringPboardType] && [[controller currentProfile] boolForKey:@"convertYenMark"])
	{
		NSMutableString *string = [NSMutableString stringWithString:[pboard stringForType:NSStringPboardType]];
		if (string)
		{
			[string replaceYenWithBackSlash];
			
			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = [self selectedRange];
			if ([self shouldChangeTextInRange:selectedRange replacementString:string])
			{
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
			return YES;
		}
		else
		{
			return NO;
		}
	}
	return [super readSelectionFromPasteboard:pboard type:type];
}
@end
