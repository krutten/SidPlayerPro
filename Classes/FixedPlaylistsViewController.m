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

#import "FixedPlaylistsViewController.h"
#import "AppDelegate.h"

@interface FixedPlaylistsViewController (Private)

- (void) deselect: (id) sender;

Sid_MachineAppDelegate* app;

@end


@implementation FixedPlaylistsViewController

@synthesize source;
@synthesize songsArray;
@synthesize refreshOnReload;
@synthesize songsFound;

- (void) buildSongsArray
{
	if (!source)
	{
		NSLog(@"Datasource is missing - can't populate view");
		return;
	}
	// refresh only if needed
	if ([self.songsArray count] == 0)
	{
		NSLog(@"empty SongArray found.");
		songsArray = [source getSongs];
	}
	
}

- (void) shuffleSongsArray
{
	NSLog(@"shufflePLaylist favorites called");
	NSMutableArray* currentSongs = self.songsArray;
	// Fisher Yates shuffle alg.
	int n = [currentSongs count];
	while (n >1)
	{
		int rnd = arc4random() % n;
		int i = n -1;
		[currentSongs exchangeObjectAtIndex:i withObjectAtIndex:rnd];
		n--;
	}
}

#pragma mark UIView methods

- (void)viewWillAppear:(BOOL)animated {
	if (([source rebuildViewNeeded]) || ([self refreshOnReload]))
	{
		[self buildSongsArray];
		[(UITableView*) [self view] reloadData];
		[self setRefreshOnReload:NO];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self buildSongsArray];
}

#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([source shuffleMode] == YES && ([self.songsArray count] > 0))
	{
		NSLog(@"With shuffle option");
		return 2;
	}
	else
	{
		NSLog(@"Without shuffle option");
		return 1;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//	if (section == 0 ) {
	if ([source shuffleMode] == YES && section == 0)
	{
		NSLog(@"section 0 asked");
		return 1;
	}
	else {
		NSLog(@"%i songs in section 1", section);
		return [songsArray count];
	}

	
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([source shuffleMode] == YES && indexPath.row == 0 && indexPath.section == 0)
		return NO;
	else
		return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([source shuffleMode] == YES && indexPath.row == 0 && indexPath.section == 0)
		return NO;
	else
		return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	// check if it's allowed to move the cell
	if (proposedDestinationIndexPath.section != sourceIndexPath.section )
		return sourceIndexPath;
	else
		return proposedDestinationIndexPath;
	
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell* cell;
	
	if ([source shuffleMode] == YES && indexPath.row == 0 && indexPath.section == 0)
	{
		// special cell for shuffle selection
		static NSString *CellIdentifier = @"buttonPlaylistCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.text = NSLocalizedString(@"playlist command shuffle", @"");
		cell.textAlignment = UITextAlignmentCenter;
		cell.selected = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		[cell setImage: [UIImage imageNamed:@"shuffle.png"]];
		return cell;
	}

	Song* selectedSong	= (Song*)[songsArray objectAtIndex:indexPath.row];

    if ([source defaulCellType])
	{
		// build a default cell view
		static NSString *CellIdentifier = @"defaultPlaylistCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
	}
	else
	{
		UILabel* newLabel;
		static NSString *CellIdentifier = @"specialPlaylistCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			// no cell found, let's create one!
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
			newLabel = [[UILabel alloc] initWithFrame:CGRectMake(250.0f, 12.0f, 50.0f, 20.0f)];
			[newLabel setTag: 001];
			[cell addSubview: newLabel];
			[cell setAccessoryView: newLabel];
			[newLabel release];
		}
		// there must be a correct cell
		newLabel = (UILabel*) [cell viewWithTag:001];
		[newLabel setTextAlignment: UITextAlignmentRight];
		[newLabel setText:[NSString stringWithFormat: @"%i", [selectedSong playedCounter]]];
		[newLabel setBackgroundColor:[UIColor clearColor]];
		
	}
	// Set the cell's text to the name of the time zone at the row
	[cell setText: selectedSong.name];
	[cell setTextAlignment: UITextAlignmentLeft];
	[cell setImage: [UIImage imageNamed:@"unchecked.png"]];
	if (selectedSong.problemFound == YES)
		[cell setImage: [UIImage imageNamed:@"problem.png"]];
	else if (selectedSong.cached == YES)
		[cell setImage: [UIImage imageNamed:@"checked.png"]];
	[cell setSelected:NO];

	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([source shuffleMode] == YES && indexPath.section == 0)
	{
		//shuffle hit -> let's go
		if ([source shuffleMode] == YES)
			[self shuffleSongsArray];
		[self.tableView reloadData];
		// add some effects here!
	}
	else
	{
		Song* selectedSong	= [songsArray objectAtIndex:indexPath.row];
		NSLog(@"selected song name: %@, uri: %@", selectedSong.name, selectedSong.uri);
		
		// setup new playlist Array
		[app updatePlaylist:(id) self];
		[app showPlayerWithSong:self WithSong:selectedSong];
		[self setRefreshOnReload:YES];
		[self performSelector:@selector(deselect:) withObject:tableView afterDelay:0.25f];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Song* selectedSong	= [songsArray objectAtIndex:indexPath.row];
		NSLog(@"deleteing song name: %@, uri: %@", selectedSong.name, selectedSong.uri);

		[source deleteSong:selectedSong];
		// Delete the row from the data source
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	}
}

// remove cell selection
- (void) deselect: (id) sender
{
	NSLog(@"Deselecting favorites cell");
	[(UITableView*) sender deselectRowAtIndexPath:[sender indexPathForSelectedRow] animated:YES];
}


- (void)dealloc {
    [super dealloc];
	[source release];
	[songsArray release];
}


@end
