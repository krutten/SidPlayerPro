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

#import "SongslistViewController.h"
#import "PlayerViewController.h"
#import "AppDelegate.h"
#import "Song.h"

@interface SongslistViewController (private)
	-(void) setUpDisplayList;
@end

// --------------------------------------------------
// the fun starts here
// --------------------------------------------------
@implementation SongslistViewController

@synthesize songsArray;
@synthesize indexedSongs;
@synthesize displayList;
@synthesize indexLetters;

- (void)dealloc
{
	[songsArray release];
	[indexedSongs release];
	[displayList release];
	[indexLetters release];
    [super dealloc];
}

// -----------------------------------------------------------------
// IBAction Methods
// -----------------------------------------------------------------
-(IBAction)showPlayer:(id)sender
{
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[appDelegate showPlayer:sender];
}



// -----------------------------------------------------------------
// UITableViewController Methods
// -----------------------------------------------------------------

// used for the moment to show some informations text only
- (void)viewDidLoad
{
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:(UIBarButtonSystemItem)UIBarButtonSystemItemPlay
								   target:self
								   action:@selector(showPlayer:)] autorelease];
	self.navigationItem.rightBarButtonItem = addButton;

	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	songsArray = [[appDelegate database] getSongs: [[appDelegate pkAuthor] intValue]];
	if (! self.indexedSongs)
		self.indexedSongs = [[NSMutableDictionary alloc] init];
	[self setUpDisplayList];
}

- (void)viewWillAppear:(BOOL)animated {
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if ([[appDelegate database] rebuildCache]) {
		songsArray = [[appDelegate database] getSongs: [[appDelegate pkAuthor] intValue]];
		[self setUpDisplayList];
		[(UITableView*) [self view] reloadData];
		[[appDelegate database] setRebuildCache:NO];
	}
}


// number of sections in the songs dictionary
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	int sections = [displayList count];
	if (sections == 0)
		return 1;
	else
		return sections;
}

// used to build the index to the right sider
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	/* show index only, if more then 15 sections ar found */
	if ([displayList count] > 15)
		return [displayList valueForKey:@"letter"];
	else
		return NO;
}


// -----------------------------------------------------------------
// tableView Methods
// -----------------------------------------------------------------

// number of rows in a given section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([displayList count] == 0)
		return 1;
	NSDictionary *letterDictionary = [displayList objectAtIndex:section];
	NSArray *zonesForLetter = [letterDictionary objectForKey:@"songsDic"];
	return [zonesForLetter count];
}

// return the header name for a give section
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([displayList count] == 0)
		return nil;
	NSDictionary *sectionDictionary = [displayList objectAtIndex:section];
	return [sectionDictionary valueForKey:@"letter"];
}

// get a table cell for viewing
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MyCell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
		// no cell found, create one
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	if ([displayList count] == 0) {
		[cell setText:NSLocalizedString(@"No Songs found", @"")];
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];
		[cell setImage: [UIImage imageNamed:@"unchecked.png"]];
	}
	else
	{
		NSDictionary *letterDictionary = [displayList objectAtIndex:indexPath.section];
		NSArray *songsForLetter = [letterDictionary objectForKey:@"songsDic"];
		NSDictionary *songsDictionary = [songsForLetter objectAtIndex:indexPath.row];
		
		Song* selectedSong	= [songsDictionary objectForKey:@"song"];
		// Set the cell's text to the name of the time zone at the row
		[cell setText:[selectedSong name]];

		if (selectedSong.problemFound == YES)
			[cell setImage: [UIImage imageNamed:@"problem.png"]];
		else if (selectedSong.cached == YES)
			[cell setImage: [UIImage imageNamed:@"checked.png"]];
		else
			[cell setImage: [UIImage imageNamed:@"unchecked.png"]];
	}		
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	return cell;
}

// cell pressed - get song & play it
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([displayList count] == 0) return;
	NSDictionary* letterDictionary = [displayList objectAtIndex:indexPath.section];
	NSArray* songsForLetter = [letterDictionary objectForKey:@"songsDic"];
	NSDictionary* songsDictionary = [songsForLetter objectAtIndex:indexPath.row];

	Song* selectedSong	= [songsDictionary objectForKey:@"song"];
	NSLog(@"selected song name: %@, uri: %@", selectedSong.name, selectedSong.uri);

	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];

	// hier neue Playlist setzen!
	[appDelegate updatePlaylist:(id) self];
	[appDelegate showPlayerWithSong:self WithSong:selectedSong];
	[(UITableView*) tv reloadData];
}


# pragma mark -
# pragma mark private Methods
#pragma mark -

// init method to fill the needed dictionaries (arrays)
- (void)setUpDisplayList {
	[self.indexedSongs removeAllObjects];

	for (Song* currentSong in songsArray) {
		NSString *mySongName	= (NSString *) [currentSong name];
		NSString *firstLetter	= [mySongName substringToIndex:1].uppercaseString;
		// uppercase first letter -> it's better

		// if fistletter is a special char -> put it into # section
		if([firstLetter caseInsensitiveCompare:@"a"] == NSOrderedAscending ||
		   [firstLetter caseInsensitiveCompare:@"Z"] == NSOrderedDescending)  {
				firstLetter = @"#";
		}

		// if the name is not a correct string -> fix it!
		if (firstLetter == nil) {
			NSLog(@"Check DB Entry with ID: %i - useing default value", currentSong.primaryKey);
			firstLetter = @" ";
		}


		// get matching array or create one if not found
		NSMutableArray *indexArray = [self.indexedSongs objectForKey:firstLetter];
		if (indexArray == nil) {
			indexArray = [[NSMutableArray alloc] init];
			[self.indexedSongs setObject:indexArray forKey:firstLetter];
			[indexArray release];
		}
		NSDictionary *songsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:mySongName, @"songNames", currentSong, @"song", nil];
		[indexArray addObject:songsDictionary];
		[songsDictionary release];
	}

	NSMutableArray *nameSections = [[NSMutableArray alloc] init];

	// Normally we'd use a localized comparison to present information to the user, but here we know the data only contains unaccented uppercase letters
	self.indexLetters = [[self.indexedSongs allKeys] sortedArrayUsingSelector:@selector(compare:)];

	for (NSString *indexLetter in indexLetters) {
		NSMutableArray *nameSectionsDictionaries = [self.indexedSongs objectForKey:indexLetter];
		NSDictionary *letterDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:indexLetter, @"letter", nameSectionsDictionaries, @"songsDic", nil];
		[nameSections addObject:letterDictionary];
		[letterDictionary release];
	}

	self.displayList = nameSections;
	[nameSections release];

}

@end

