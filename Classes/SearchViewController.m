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

#import "SearchViewController.h"
#import "SongsByAuthorViewController.h"

#import	"AppDelegate.h"
#import "Song.h"
#import "SearchCell.h"
#import "SearchCellMore.h"

@implementation SearchViewController

@synthesize mySearchBar;
@synthesize songsArray;
@synthesize myTableView;
@synthesize restartSeach;
@synthesize ignoreResults;
@synthesize ignoreSelector;
@synthesize myTimer;
@synthesize moreId;


- (void)dealloc {
	[mySearchBar release];
	[songsArray release];
	[myTableView release];
	[myTimer release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSLog(@"SearchViewController appears. SearchBar has %d characters", mySearchBar.text.length );

	if (!animated) {
        [mySearchBar resignFirstResponder];
    }
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
//	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (([app restartSearch]) && ([app lastSearch].length > 1)) {
		NSLog(@"let's rebuild search, for '%@'", [app lastSearch]);
		[[app database]searchSongsFor: self];
	}
	
	lastTapTime     = 0;
	lastTapRow      = -1;
	self.ignoreSelector = NO;
	
//#define AUTO_SHOW_KEYBOARD

#ifdef AUTO_SHOW_KEYBOARD
	// add some clever *cough* logic to only autoshow the keyboard if we do not have any search characters
	if ( mySearchBar.text.length > 0 )
		[mySearchBar resignFirstResponder];
	else
		[mySearchBar becomeFirstResponder];
#endif
}

- (void)viewDidLoad {
	NSLog(@"SearchViewController loaded");

	// don't get in the way of our typing in any way!
	mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	mySearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

//	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (([app.firstStart boolValue]) && ([app lastSearch].length > 1)) {
		NSLog(@"let's rebuild search, for '%@'", [app lastSearch]);
		[[app database]searchSongsFor: self];
		mySearchBar.text = [app lastSearch];
	}
	
	// this is an interactive search, swap 'Search' for 'Done' (iPhone Cookbook Recipe 8-10)
	UITextField* searchField = [[mySearchBar subviews] lastObject];
	[searchField setReturnKeyType:UIReturnKeyDone];
}

// used as a callback method when a searching thread finished
- (void)rebuildTableView
{
	NSLog(@"Callback gerufen - let's rebuild tableview now");
	if (ignoreResults == NO) {
		songsArray = [[app database] searchSongsArray];
		[myTableView reloadData];
	}

	if (restartSeach == YES)
	{
		NSLog(@"we need another search, starting now..");
		[self setRestartSeach:NO];
		[[app database]searchSongsFor: self];
	}

}


// -----------------------------------------------------------------
// private Methods
// -----------------------------------------------------------------
- (void)startSearchByTimer:(NSTimer *)theTimer
{
	[myTimer invalidate];
	[[app database] initSearch];
	[[app database] searchSongsFor: self];
}


// -----------------------------------------------------------------
// UISearch Delegate
// -----------------------------------------------------------------
#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	// check if the timer is running
	if ([myTimer isValid] == YES) {
		NSLog(@"Timer running, stopping it");
		[myTimer invalidate];
	}

	if (searchBar.text.length > 2) {
		[self setIgnoreResults:NO];
		[app setLastSearch:searchBar.text];
		// init timer here
		self.myTimer = [NSTimer scheduledTimerWithTimeInterval: 1.25 target: self selector:@selector(startSearchByTimer:) userInfo: nil repeats: NO];
	}
	else
	{
		[self setIgnoreResults:YES];
		[[app database] initSearch];
		[songsArray removeAllObjects];
		[myTableView reloadData];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	[self setIgnoreResults:NO];
	if ([[app lastSearch] compare: searchBar.text] != NSOrderedSame) {
		[app setLastSearch:searchBar.text];
		[[app database] initSearch];
		[[app database] searchSongsFor: self];
	}
}


// -----------------------------------------------------------------
// tableView Methods
// -----------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// depands on search results count
	NSInteger count = [songsArray count];
    if ([[app database] searchMoreFound])
	{
		count++;
		moreId = count;
	}
	
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* cellIdentifyer;
	if ([songsArray count] != indexPath.row)
	{
		cellIdentifyer = @"SearchCellIdentifier";
		SearchCell* cell = (SearchCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifyer];
		if (cell == nil)
		{
			NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"SearchCell"
														 owner:self
													   options:nil];
			cell = [nib objectAtIndex:0];
		}
		Song* song = (Song*)[songsArray objectAtIndex:indexPath.row];
		cell.songname.text = song.name;
		cell.songtype.text = song.type;
		cell.authorname.text = song.authorName;

		// find matching icon for the cell
		if (song.problemFound == YES)
			cell.cellIcon.image = [UIImage imageNamed:@"problem.png"];
		else if (song.cached == YES)
			cell.cellIcon.image = [UIImage imageNamed:@"checked.png"];
		else
			cell.cellIcon.image = [UIImage imageNamed:@"unchecked.png"];
		return cell;
	}
	else
	{
		cellIdentifyer = @"SearchCellMoreIdentifier";
		SearchCellMore* cell = (SearchCellMore*) [tableView dequeueReusableCellWithIdentifier:cellIdentifyer];
	    if (cell == nil)
		{
			NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"SearchCellMore"
														 owner:self
													   options:nil];
			cell = [nib objectAtIndex:0];
		}
		[cell.activityIndicator setHidden:YES];
		[cell.activityIndicator stopAnimating];
		return cell;
	}
}

// cell pressed - get song & play it
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if (([[app database] searchMoreFound] == YES) && (indexPath.row+1 == moreId))
	{
		NSLog(@"get more Searchresults...");
		[[app database] setSearchAppendResults:YES];
		[[app database] searchSongsFor: self];
		// set spinnerwheel
		SearchCellMore* cell = (SearchCellMore*) [tableView cellForRowAtIndexPath:indexPath];
		[cell.activityIndicator setHidden:NO];
		[cell.activityIndicator startAnimating];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	}
	else
	{
		Song* selectedSong	= [songsArray objectAtIndex:indexPath.row];
		NSLog(@"selected song name: %@, uri: %@", selectedSong.name, selectedSong.uri);
		
		[mySearchBar resignFirstResponder];
		CFAbsoluteTime theTimeDelta = CFAbsoluteTimeGetCurrent() - lastTapTime;
		
		// User double-tapped
		if (lastTapRow == indexPath.row && theTimeDelta < 0.6 )
		{
			SongsByAuthorViewController * targetViewController = [[SongsByAuthorViewController alloc] initWithNibName:@"SongsByAuthorViewController" bundle:nil];
			targetViewController.pkAuthor = selectedSong.pkAuthor;
			
			[targetViewController.navigationItem setTitle:selectedSong.authorName];
			[self.navigationController pushViewController:targetViewController animated:YES];
			[targetViewController release];
			self.ignoreSelector = YES;
			// No double-tap, so reset properties/variables
		}
		else
		{
			lastTapTime    = CFAbsoluteTimeGetCurrent();
			lastTapRow     = indexPath.row;
			[self performSelector:@selector(showSongsByAuthor:) withObject:selectedSong afterDelay:0.60f];
		}
	}
}

-(void) showSongsByAuthor: (Song*) newSong
{
	if (!self.ignoreSelector)
	{
		[app updatePlaylist:(id) self];
		[app showPlayerWithSong:self WithSong:newSong];
		self.ignoreSelector = NO;
	}
}

@end

