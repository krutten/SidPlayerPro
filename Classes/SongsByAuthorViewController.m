//
//  SongsByAuthorViewController.m
//  ModPlayer
//
//  Created by Kai Teuber on 03.01.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SongsByAuthorViewController.h"
#import "Song.h"
#import "SongCell.h"

@implementation SongsByAuthorViewController
@synthesize pkAuthor;

- (void)dealloc
{
	NSLog(@"SongsByAuthorViewController dealloc called");
    [super dealloc];
}

-(void)showPlayer:(id)sender
{
	[app showPlayer:sender];
}

#pragma mark ListViewController methods

// get counted prefixes for current author
-(NSArray*) getCountedArray
{
	return [[app database] songsCountedByAuthor: pkAuthor];
}


-(NSArray*) getNamesFrom:(NSInteger) start limitBy:(NSInteger) limit;
{
	return [[app database] getSongsByAuthorWith: pkAuthor startAt:start limitBy:limit]; 
}


# pragma mark UIViewDelegate

- (void)viewDidLoad
{
	[super viewDidLoad];
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *addButton = [[[UIBarButtonItem alloc]
								   initWithBarButtonSystemItem:(UIBarButtonSystemItem)UIBarButtonSystemItemPlay
								   target:self
								   action:@selector(showPlayer:)] autorelease];
	self.navigationItem.rightBarButtonItem = addButton;
	
}


- (void)viewWillAppear:(BOOL)animated
{
	if ([[app database] rebuildCache]) {
		[self initModel];
		[(UITableView*) [self view] reloadData];
		[[app database] setRebuildCache:NO];
	}
}


# pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int requestId;
	requestId = [self getDbIndex: indexPath];
	
	NSDictionary* metaSong = [[[[app database] getSongsByAuthorWith:pkAuthor startAt:requestId limitBy:1]objectAtIndex:0]retain];
	Song* selectedSong = [[app database] getSongByPK: [[metaSong valueForKey:@"id"]integerValue]];
	
	// hier neue Playlist setzen!
	[[app playlist] setPlaylistWithPKs: [[app database] getPkSongs: pkAuthor]];
	[app showPlayerWithSong:self WithSong:selectedSong];
	[self trackPlayer: indexPath];

	[metaSong release];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SongCell";
    
    SongCell* cell = (SongCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
		cell = [[[NSBundle mainBundle] loadNibNamed:@"SongCell"
											  owner:self
											options:nil] lastObject];

    }

	int requestId;
	requestId = [self getDbIndex: indexPath];

	// change song array if it doesn't fit for the request
	if ((requestId < startId) || (requestId >= endId))
	{
		[self setNamesFromIndex:(requestId / setCount)*setCount];
	}

	NSDictionary* dataDict = [[names objectAtIndex:requestId % setCount]retain];
	bool cached = [[dataDict valueForKey:@"Cached"]boolValue];
	cell.type.text = [dataDict valueForKey:@"Type"];
	cell.name.text = [dataDict valueForKey:@"Name"];

	if ( cached )
		cell.cached.image = [UIImage imageNamed:@"checked.png"];
	else
		cell.cached.image = [UIImage imageNamed:@"unchecked.png"];

	cell.selectionStyle = (UITableViewCellSelectionStyle) UITableViewCellSelectionStyleGray;
	[dataDict release];
    return cell;
}

#pragma mark CellNotificationDelegate

- (void) startPlayback
{
	NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:self.indexPathSelected.row  + self.indexPathOffset inSection:self.indexPathSelected.section];
	SongCell* cell = (SongCell*) [(UITableView*) self.view cellForRowAtIndexPath:newIndexPath];
	cell.cached.image = [UIImage imageNamed:@"checked.png"];
	
	int requestId = [self getDbIndex:newIndexPath ];
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
