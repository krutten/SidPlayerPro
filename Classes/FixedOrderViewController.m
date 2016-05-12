//
//  FixedOrderViewController.m
//  ModPlayer
//
//  Created by Kai Teuber on 03.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "FixedOrderViewController.h"
#import "SongCell.h"
#import "SongsByAuthorViewController.h"


@implementation FixedOrderViewController

@synthesize delegate;
@synthesize ignoreSelector;
@synthesize lastIndexPath;


- (void)dealloc
{
	[(NSObject*) delegate release];
    self.lastIndexPath = nil;
    
    [super dealloc];
}

// get counted prefixes for current author
- (NSArray*) getCountedArray
{
	// we don't need sctions yet
	return [NSArray arrayWithObjects:
			[NSNumber numberWithInteger:[self.delegate countedSongs]],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			[NSNumber numberWithInteger:0],
			nil];
}


-(NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return nil;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

-(NSArray*) getNamesFrom:(NSInteger) start limitBy:(NSInteger) limit;
{
	// we need to ask the delegate
	return [self.delegate getSongNames:start limitBy:limit];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	numberOfCommands = 0;
	// check of supported commands by the delegate
	if ([(NSObject*) self.delegate respondsToSelector: @selector(shufflePlaylist)])
		numberOfCommands++;
}

- (void)viewWillAppear:(BOOL)animated
{
	lastTapTime     = 0;
	lastTapRow      = -1;
	self.ignoreSelector = NO;
}


#pragma mark UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (numberOfCommands > 0 && indexPath.row == 0 && indexPath.section == 0)
		return NO;
	else
		return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSLog(@"deleteing song name");
		int requestId;
		requestId = [self getDbIndex:indexPath skipOffest:numberOfCommands];
		
		// getSongNames:(NSInteger) start limitBy:(NSInteger) limit;
		NSDictionary* metaSong = [[[self.delegate getSongNames: requestId limitBy:1]objectAtIndex:0]retain];
		[self.delegate deleteSong:[[metaSong valueForKey:@"id"]integerValue]];

		// we need to update the datamodel
		[self initModel];
		
		// Delete the row from the data source
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		[metaSong release];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (numberOfCommands > 0)
		return 2;
	else
		return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (numberOfCommands == 0)
		return [super tableView:tableView numberOfRowsInSection:section];
	else if (section == 0)
		return numberOfCommands;
	else if ([metaData count] == 0)
		return 0;
	else
	{
		section--;
		// get meta data
		NSDictionary* sectionMetaData = [metaData objectAtIndex:section];
		int count = [[sectionMetaData objectForKey:@"Count"] integerValue];
		NSLog(@"counted %i songs in section %i", count, section);
		return count;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	UITableViewCell* cell;
	
	if (numberOfCommands > 0 && indexPath.row == 0 && indexPath.section == 0)
	{
		// special cell for shuffle selection
		static NSString *CellIdentifier = @"buttonPlaylistCell";
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
		cell.textLabel.text = NSLocalizedString(@"playlist command shuffle", @"");
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.selected = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.imageView.image = [UIImage imageNamed:@"shuffle.png"];
	}
	else
	{
		static NSString *CellIdentifier = @"SongCell";
		
		cell = (SongCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil)
		{
			cell = [[[NSBundle mainBundle] loadNibNamed:@"SongCell"
												  owner:self
												options:nil] lastObject];
		}
		
		int requestId = [self getDbIndex:indexPath skipOffest:numberOfCommands ];
		// change song array if it doesn't fit for the request
		if ((requestId < startId) || (requestId >= endId))
		{
			[self setNamesFromIndex:(requestId / setCount)*setCount];
		}
		
		NSDictionary* dataDict = [[names objectAtIndex:requestId % setCount]retain];
		
		bool cached = [[dataDict valueForKey:@"Cached"]boolValue];
		((SongCell*) cell).type.text = [dataDict valueForKey:@"Type"];
		((SongCell*) cell).name.text = [dataDict valueForKey:@"Name"];
		
		if ( cached )
			((SongCell*) cell).cached.image = [UIImage imageNamed:@"checked.png"];
		else
			((SongCell*) cell).cached.image = [UIImage imageNamed:@"unchecked.png"];
		
		//		cell.selectionStyle = (UITableViewCellSelectionStyle) UITableViewCellSelectionStyleGray;
		[dataDict release];
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (numberOfCommands > 0 && indexPath.section == 0)
	{
		NSLog(@"We need to shuffle the array!");
		[self.delegate shufflePlaylist];
		[self initModel];
		[tableView reloadData];
		// add some effects here!
	}
	else
	{
		int requestId = [self getDbIndex:indexPath skipOffest:numberOfCommands];
		NSDictionary* metaSong = [[[self.delegate getSongNames:requestId limitBy:1]objectAtIndex:0]retain];
		NSLog(@"Song selected: %i",[[metaSong valueForKey:@"id"]integerValue] );
		Song* selectedSong = [[app database] getSongByPK: [[metaSong valueForKey:@"id"]integerValue]];
		[metaSong release];

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
			self.lastIndexPath = indexPath;
		}
	}
}

-(void) showSongsByAuthor: (Song*) newSong
{
	if (!self.ignoreSelector)
	{
		[[app playlist] setPlaylistWithPKs: [delegate getPlaylistPKs]];
		[app showPlayerWithSong:self WithSong:newSong];
		[self trackPlayer: self.lastIndexPath];
		self.ignoreSelector = NO;
	}
}

#pragma mark CellNotificationDelegate

- (void) startPlayback
{
	NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:self.indexPathSelected.row  + self.indexPathOffset inSection:self.indexPathSelected.section];
	SongCell* cell = (SongCell*) [(UITableView*) self.view cellForRowAtIndexPath:newIndexPath];
	cell.cached.image = [UIImage imageNamed:@"checked.png"];
	
	int requestId = [self getDbIndex:newIndexPath skipOffest:numberOfCommands ];
	
	// change song array if it doesn't fit for the request
	if ((requestId < startId) || (requestId >= endId))
	{
		[self setNamesFromIndex:(requestId / setCount)*setCount];
	}
	
	NSDictionary* dataDict = [[names objectAtIndex:requestId % setCount]retain];
	NSDictionary* newDataDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 [dataDict objectForKey:@"id"], @"id",
								 [dataDict objectForKey:@"Name"], @"Name",
								 [NSNumber numberWithBool:YES], @"Cached",
								 [dataDict objectForKey:@"Type"], @"Type",
								 nil];
	[names replaceObjectAtIndex:requestId % setCount withObject:newDataDict];
	
	[dataDict release];
}


@end
