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

#import "MusicianViewController.h"
#import "SongslistViewController.h"
#import "PlayerViewController.h"
#import "AppDelegate.h"
#import "Song.h"

@interface MusicianViewController (Private)
	-(void) initDataStructure;
	Sid_MachineAppDelegate* app;

@end

@implementation MusicianViewController

-(void)viewDidLoad
{
	NSLog(@"MusicianViewController: viewDidLoad");
	app = (Sid_MachineAppDelegate*) [[UIApplication sharedApplication] delegate];
//	[app.database rebuildAuthors];
}

-(void)viewWillAppear:(BOOL)animated
{
	if (app.database.authorsHaveChanged)
	{
		app.database.authorsHaveChanged = false;
		[(UITableView*)[self view] reloadData];
	}
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger sections = [app.database.musiciansLetters count];
	return sections > 0 ? sections : 1;
}

-(NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return [app.database.musiciansLettersIndexed count] > 5 ? app.database.musiciansLettersIndexed : nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSInteger sections = [app.database.musiciansLetters count];
	if (!sections)
		return nil;
	return [app.database.musiciansLettersIndexed objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger sections = [app.database.musiciansLetters count];
	if (!sections)
		return 1;
	NSString* letter = [app.database.musiciansLettersIndexed objectAtIndex:section];
	return [[app.database.musiciansLetters objectForKey:letter] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"indexPath = %i.%i", indexPath.section, indexPath.row);
    static NSString* CellIdentifier = @"AuthorsCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
	{
		// no cell found, create one
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	NSInteger sections = [app.database.musiciansLetters count];
	if (!sections)
	{
		[cell setText:NSLocalizedString(@"No Songs found", @"")];
	}
	else
	{
		NSString* key = [NSString stringWithFormat:@"A%i:%i", indexPath.section, indexPath.row];
		[cell setText:[app.database.musiciansIndexed valueForKey:key]];
	}
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSString* keyA = [NSString stringWithFormat:@"A%i:%i", indexPath.section, indexPath.row];
	NSString* keyP = [NSString stringWithFormat:@"P%i:%i", indexPath.section, indexPath.row];
	
	NSString* pkAuthor = [NSString stringWithFormat:@"%i", [[app.database.musiciansIndexed valueForKey:keyP] integerValue]];
	NSString* authorName = [app.database.musiciansIndexed valueForKey:keyA];
	
	[app setPkAuthor:pkAuthor];
	[app setAuthorName:authorName];
	
	SongslistViewController *targetViewController;
	targetViewController = [[SongslistViewController alloc] initWithNibName:@"SongslistWindow" bundle:nil];
	[targetViewController.navigationItem setTitle:authorName];
	
	UINavigationController* navCon = [self navigationController];
	[navCon pushViewController:targetViewController animated:YES];	
}

# pragma mark -
# pragma mark IBActions
# pragma mark -

-(IBAction)showPlayer:(id)sender {
	// turn off root NavigationBar
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[appDelegate showPlayer:sender];
}

// special back Button
-(IBAction)backAction:(id)sender {
	NSLog(@"backAction pressed");
	[[self navigationController] popViewControllerAnimated:YES];
}


@end
