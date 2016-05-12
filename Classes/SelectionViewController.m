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

#import "SelectionViewController.h"
#import "FixedOrderViewController.h"
#import "EditableOrderViewController.h"


@implementation SelectionViewController

@synthesize fixedPlaylists;
@synthesize editabledPlaylists;
@synthesize doubleTapNotice;

// init some things here
- (void)viewDidLoad {
    [super viewDidLoad];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (self.fixedPlaylists == nil)
		self.fixedPlaylists = [app.database getPlaylists:@"fixed"];
	if (self.editabledPlaylists == nil)
		self.editabledPlaylists = [app.database getPlaylists:@"modifiable"];
	
	self.doubleTapNotice.text = NSLocalizedString(@"doubleTap", @"");
	
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// two fix sections for the moment
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0 )
		return [self.editabledPlaylists count];
	else
		return [self.fixedPlaylists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"SelectionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSDictionary* playlistDictionary;
	if (indexPath.section == 0)
		playlistDictionary = [self.editabledPlaylists objectAtIndex:indexPath.row];
		
	else
		playlistDictionary = [self.fixedPlaylists objectAtIndex:indexPath.row];

	NSString* playlistName = [NSString stringWithFormat:@"%@ %@", @"Playlist", [playlistDictionary objectForKey:@"playlistName"]];
	[cell.textLabel setText:NSLocalizedString(playlistName, @"")];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSDictionary* playlistDictionary;
	
	if (indexPath.section == 0)
	{
		playlistDictionary = [self.editabledPlaylists objectAtIndex:indexPath.row];
		// TODO: ask source obj and load another xib with shuffle button included!
		EditableOrderViewController* targetViewController = [[EditableOrderViewController alloc] initWithStyle:UITableViewStyleGrouped];

		NSString* calssName = [NSString stringWithFormat: @"Source%@", [playlistDictionary objectForKey:@"playlistName"]];
		id sourceObj = [[NSClassFromString(calssName) alloc] init];
		[targetViewController setDelegate: sourceObj];
		[sourceObj release];
		
		NSString* playlistName = [NSString stringWithFormat:@"%@ %@", @"Playlist", [playlistDictionary objectForKey:@"playlistName"]];
		[targetViewController.navigationItem setTitle:NSLocalizedString(playlistName, @"")];
		
		UINavigationController* navCon = [self navigationController];
		[navCon pushViewController:targetViewController animated:YES];
		[targetViewController release];
	}
	else
	{
		playlistDictionary = [self.fixedPlaylists objectAtIndex:indexPath.row];
		FixedOrderViewController* targetViewController = [[FixedOrderViewController alloc] initWithStyle:UITableViewStyleGrouped];
		NSString* calssName = [NSString stringWithFormat: @"Source%@", [playlistDictionary objectForKey:@"playlistName"]];
		id sourceObj = [[NSClassFromString(calssName) alloc] init];
		[targetViewController setDelegate: sourceObj];
		[sourceObj release];

		NSString* playlistName = [NSString stringWithFormat:@"%@ %@", @"Playlist", [playlistDictionary objectForKey:@"playlistName"]];
		[targetViewController.navigationItem setTitle:NSLocalizedString(playlistName, @"")];
		
		UINavigationController* navCon = [self navigationController];
		[navCon pushViewController:targetViewController animated:YES];
		[targetViewController release];
	}

}


- (void)dealloc {
	[editabledPlaylists release];
	[fixedPlaylists release];
	[doubleTapNotice release];
    [super dealloc];
}

@end

