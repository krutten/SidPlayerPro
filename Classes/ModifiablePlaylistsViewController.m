/*
 * Sid Player -- Bringing the C64 Classics to the iPhone
 * (C) 2008-2009 Lauer, Teuber GbR <sidplayer@vanille.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "ModifiablePlaylistsViewController.h"
#import "AppDelegate.h"


@interface ModifiablePlaylistsViewController (private)

Sid_MachineAppDelegate*	app;

@end


@implementation ModifiablePlaylistsViewController

@synthesize rebuild;

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	NSLog(@"Toogle editmode");
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:YES];
	if (rebuild)
	{
		[[app database] autoincrementPosition:songsArray];
		[self setRebuild:NO];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	// lets move the selected song
	Song* movedSong = [songsArray objectAtIndex:fromIndexPath.row];
	if (fromIndexPath.row < toIndexPath.row)
	{
		// move down
		[songsArray insertObject:movedSong atIndex:toIndexPath.row+1];
		[songsArray removeObjectAtIndex:fromIndexPath.row];
	}
	else
	{
		// move up
		[songsArray insertObject:movedSong atIndex:toIndexPath.row];
		[songsArray removeObjectAtIndex:fromIndexPath.row+1];
	}
	[self setRebuild:YES];
}
@end

