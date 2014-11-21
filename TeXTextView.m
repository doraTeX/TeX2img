#import "TeXTextView.h"
#import "NSDictionary-Extension.h"
#import "NSMutableString-Extension.h"

static BOOL isValidTeXCommandChar(int c);

static BOOL isValidTeXCommandChar(int c)
{
	if ((c >= 'A') && (c <= 'Z'))
		return YES;
	else if ((c >= 'a') && (c <= 'z'))
		return YES;
	else if (c == '@')
		return YES;
	else
		return NO;
}


@implementation TeXTextView
- (id)init
{
	[super init];
	_lastCursorLocation = 0;
	return self;
}


- (void)insertText:(id)aString
{
	NSDictionary* currentProfile = [controller currentProfile];

	if([aString isEqualToString:@"¥"] && [currentProfile boolForKey:@"convertYenMark"])
	{
		[super insertText:@"\\"];
	}
	else
	{
		[super insertText:aString];
	}
	[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
}


// クリップボードから貼り付けられる円マークをバックスラッシュに置き換えて貼り付ける
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	NSDictionary* currentProfile = [controller currentProfile];

	if([type isEqualToString:NSStringPboardType] && [currentProfile boolForKey:@"convertYenMark"])
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
			[self colorizeText:[currentProfile boolForKey:@"colorizeText"]];
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
