//
//  EditableOrderViewController.m
//  ModPlayer
//
//  Created by Kai Teuber on 11.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "EditableOrderViewController.h"


@implementation EditableOrderViewController

@synthesize refresh;

// disable editing for command rows
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (numberOfCommands > 0 && indexPath.row == 0 && indexPath.section == 0)
		return NO;
	else
		return YES;
}

// limit moveable cells to section
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (proposedDestinationIndexPath.section != sourceIndexPath.section )
		return sourceIndexPath;
	else
		return proposedDestinationIndexPath;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	NSLog(@"Toogle editmode");
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
	if (self.refresh == YES)
	{
		NSLog(@"Die DB braucht ein Update!");
		[[app database] autoincrementPosition:[delegate getPlaylistPKs]];
		self.refresh = NO;
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	// must be done by the delegate
	self.refresh = [self.delegate moveSongFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
}


#pragma mark CellNotificationDelegate

- (void) favoriteToggle: (BOOL) favorite
{
	NSLog(@"Favorite Toggled ");
	[(NSObject*) self.delegate init];
	[self initModel];
	[self.tableView reloadData];
}

@end
