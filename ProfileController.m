#import "ProfileController.h"
#import "NSMutableDictionary-Extension.h"
#import "NSDictionary-Extension.h"
#import "NSIndexSet-Extension.h"

#define MovedRowsType @"TeX2imgMovedRowsType"

@implementation ProfileController
 - (NSMutableDictionary*)profileForName:(NSString*)profileName
{
	int targetIndex = [profileNames indexOfObject:profileName];
	return (targetIndex==NSNotFound) ? nil : [NSMutableDictionary dictionaryWithDictionary:[profiles objectAtIndex:targetIndex]];
}

- (void)loadProfilesFromPlist
{
	profileNames = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"profileNames"]] retain]; // retain しておかないと失われる
	profiles =  [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"profiles"]] retain];
}

- (void)initProfiles
{
	profileNames = [[NSMutableArray arrayWithCapacity:0] retain]; // retain しておかないと失われる
	profiles = [[NSMutableArray arrayWithCapacity:0] retain];
}

- (void)releaseProfiles
{
	[profileNames release];
	[profiles release];
}

- (void)removeProfileForName:(NSString*)profileName
{
	int targetIndex = [profileNames indexOfObject:profileName];
	if(targetIndex == NSNotFound) return;
	[profileNames removeObjectAtIndex:targetIndex];
	[profiles removeObjectAtIndex:targetIndex];
}

- (void)updateProfile:(NSDictionary*)aProfile forName:(NSString*)profileName
{
	int targetIndex = [profileNames indexOfObject:profileName];
	if(targetIndex == NSNotFound)
	{
		[profileNames addObject:profileName];
		[profiles addObject:aProfile];
	}
	else
	{
		[profileNames replaceObjectAtIndex:targetIndex withObject:profileName];
		[profiles replaceObjectAtIndex:targetIndex withObject:aProfile];
	}
}

- (void)saveProfiles
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:profileNames forKey:@"profileNames"];
	[userDefaults setObject:profiles forKey:@"profiles"];
	[userDefaults synchronize];
}


- (int)numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [profileNames count];
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
	return [profileNames objectAtIndex:rowIndex];
}


- (IBAction)addProfile:(id)sender
{
	NSString *newProfileName = [saveAsTextField stringValue];
	
	if([newProfileName isEqualToString:@""])
	{
		NSBeep();
		NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"emptyProfileNameErrMsg", nil), @"OK", nil, nil);	
	}
	else
	{
		int aIndex = [profileNames indexOfObject:newProfileName];
		if(aIndex == NSNotFound)
		{
			[self updateProfile:[controllerG currentProfile] forName:newProfileName];
			[saveAsTextField setStringValue:@""];
			[profilesWindow makeFirstResponder:saveAsTextField]; // フォーカスを入力欄に
		}
		else
		{
			if(NSRunAlertPanel(NSLocalizedString(@"Confirm", nil), NSLocalizedString(@"profileOverwriteMsg", nil), @"OK", NSLocalizedString(@"Cancel", nil), nil) == NSOKButton)
			{
				[self updateProfile:[controllerG currentProfile] forName:newProfileName];
				[saveAsTextField setStringValue:@""];
			}
			else
			{
				[profilesWindow makeFirstResponder:saveAsTextField]; // フォーカスを入力欄に
			}
		}
		[profilesTableView reloadData];
	}
    
}

- (IBAction)loadProfile:(id)sender
{
    int selectedIndex = [profilesTableView selectedRow];
	if(selectedIndex == -1) return;
	
	[controllerG adoptProfile:[profiles objectAtIndex:selectedIndex]];
	[profilesWindow close];
}

- (IBAction)removeProfile:(id)sender
{
    int selectedIndex = [profilesTableView selectedRow];
	if(selectedIndex == -1) return;
	
	[profileNames removeObjectAtIndex:selectedIndex];
	[profiles removeObjectAtIndex:selectedIndex];
	
	[profilesTableView reloadData];
	
}

- (void)awakeFromNib
{
	[profilesTableView setTarget:self];
	[profilesTableView setAction:@selector(setSelectedProfileName:)];
	[profilesTableView setDoubleAction:@selector(loadProfile:)];

	[profilesTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[profilesTableView registerForDraggedTypes:[NSArray arrayWithObjects:MovedRowsType, nil]];
}

- (void)dealloc
{
	[self releaseProfiles];
	[super dealloc];
}

- (IBAction)setSelectedProfileName:(id)sender
{
	int selectedIndex = [profilesTableView selectedRow];
	if(selectedIndex == -1) return;

	[saveAsTextField setStringValue:[profileNames objectAtIndex:selectedIndex]];
}

- (void)showProfileWindow
{
	[profilesWindow makeKeyAndOrderFront:nil];
}


////////// ここからドラッグ＆ドロップによる行の並べ替え関連 //////////
- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	 toPasteboard:(NSPasteboard *)pboard
{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:MovedRowsType, nil];
	[pboard declareTypes:typesArray owner:self];
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:MovedRowsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)aTableView 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// 行間へのドロップは許すが，行自体へのドロップ(NSTableViewDropOn)は許さない
    [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];

    if ([info draggingSource] == profilesTableView)
	{
		return NSDragOperationMove;
    }
	return nil;
}

- (NSIndexSet*)moveObjectsOf:(NSMutableArray*)anArray
				 fromIndexes:(NSIndexSet*)fromIndexSet 
					 toIndex:(unsigned int)insertIndex
{	
	// If any of the removed objects come before the insertion index,
	// we need to decrement the index appropriately
	unsigned int adjustedInsertIndex = insertIndex - [fromIndexSet countOfIndexesInRange:(NSRange){0, insertIndex}];
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, [fromIndexSet count]);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [anArray objectsAtIndexes:fromIndexSet];
	[anArray removeObjectsAtIndexes:fromIndexSet];	
	[anArray insertObjects:objectsToMove atIndexes:destinationIndexes];

	return destinationIndexes;
	
}

- (BOOL)tableView:(NSTableView*)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)insertionRow
	dropOperation:(NSTableViewDropOperation)op
{
    if (insertionRow < 0)
	{
		insertionRow = 0;
	}
	// if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == profilesTableView)
	{
		
		NSEvent *currentEvent = [NSApp currentEvent];
		int optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		
		if (optionKeyPressed == 0)
		{
			NSData *rowsData = [[info draggingPasteboard] dataForType:MovedRowsType];
			NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
			NSIndexSet *newIndexes = [self moveObjectsOf:profileNames fromIndexes:indexSet toIndex:insertionRow];
			[self moveObjectsOf:profiles fromIndexes:indexSet toIndex:insertionRow];
			[aTableView selectRowIndexes:newIndexes byExtendingSelection:NO]; // 今動かしたばかりの行を選択する
			[aTableView reloadData];
			return YES;
		}
    }
	
    return NO;
}
////////// ここまでドラッグ＆ドロップによる行の並べ替え関連 //////////

@end
