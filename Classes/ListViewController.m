//
//  ListViewController.m
//  ModPlayer
//
//  Created by Kai Teuber on 18.01.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "ListViewController.h"
#import "SongCell.h"



#define kSetSize 50

@implementation ListViewController

@synthesize indexPathSelected, indexPathOffset;

- (void)dealloc
{
	app.playerController.delegate = nil;
    self.indexPathSelected = nil;
    
	[realData release];
	[realPrefixes release];
	[names release];
	[metaData release];
    [super dealloc];
}

- (void) initModel
{
	// init song array
	  [self setNamesFromIndex: 0];
	
	//	// build prefix Array
	NSArray* prefixes = [[NSArray arrayWithObjects: @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", \
						  @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil]retain];
	
	
	if (realPrefixes)
		[realPrefixes release];
	realPrefixes = [[NSMutableArray alloc]init];

	
	NSArray* counted = [[self getCountedArray]retain];
	
	NSInteger start = 1;
	NSInteger index = 0;
	if (metaData)
		[metaData release];
	metaData = [[NSMutableArray alloc]init];
	
	for (NSNumber* no in counted)
	{
		NSNumber* count = [[counted objectAtIndex:index]retain];
		
		if ([count intValue] > 0)
		{
			[metaData addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [prefixes objectAtIndex:index], @"Name",
								 [NSNumber numberWithInt:start], @"Start",
								 count, @"Count",
								 nil]];
			[realPrefixes addObject:[prefixes objectAtIndex:index]];
		}
		start += [[counted objectAtIndex:index] integerValue];
		index++;
		[count release];
	}
	[prefixes release];
	[counted release];
	
	// array with the real data
	if (realData)
		[realData release];
	realData = [[NSMutableArray alloc]init];

}

- (void)viewDidLoad {
	
	setCount = kSetSize;
	
	NSLog(@"ListViewController: viewDidLoad");
	app = [(Sid_MachineAppDelegate*) [[UIApplication sharedApplication] delegate] retain];
	[self initModel];
}


// override to get the correct counted prefixes!
-(NSArray*) getCountedArray
{
	return [NSArray array];
}

-(NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return realPrefixes;
}


-(NSArray*) getNamesFrom:(NSInteger) start limitBy:(NSInteger) limit;
{
	return [NSArray array];
}

// set a new set of songs to the internal array
- (void) setNamesFromIndex: (NSInteger) start
{
	if (names)
		[names release];
	
	startId = (start == 0) ? 0 : (start / kSetSize)*kSetSize;
	endId = startId + kSetSize;
	NSLog(@"new ids set, start = %i & end = %i", startId, endId);
	
	names = [[self getNamesFrom: startId limitBy:kSetSize]retain];
}

- (int) getDbIndex: (NSIndexPath *) indexPath
{
	return [self getDbIndex:indexPath skipOffest:0];
}

- (int) getDbIndex: (NSIndexPath *) indexPath skipOffest:(NSInteger) offset
{
	// get meta data
	NSDictionary* sectionMetaData = [metaData objectAtIndex:indexPath.section - offset];
	
	int requestId = [[sectionMetaData objectForKey:@"Start"] integerValue] -1;
	requestId += indexPath.row;
	return requestId;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [metaData count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// get meta data
	NSDictionary* sectionMetaData = [metaData objectAtIndex:section];
	NSString* name = [sectionMetaData objectForKey:@"Name"];
	
	return name;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// get meta data
	NSDictionary* sectionMetaData = [metaData objectAtIndex:section];
	int count = [[sectionMetaData objectForKey:@"Count"] integerValue];
//	NSLog(@"counted %i songs in section %i", count, section);
	return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell_new";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
	
	int requestId;
	requestId = [self getDbIndex: indexPath];
	
	// change song array if it doesn't fit for the request
	if ((requestId < startId) || (requestId >= endId))
	{
		[self setNamesFromIndex:(requestId / setCount)*setCount];
	}
	
	NSDictionary* dataDict = [[names objectAtIndex:requestId % setCount]retain];
	cell.textLabel.text = [dataDict valueForKey:@"Name"];
	cell.detailTextLabel.text = [[dataDict valueForKey:@"Count"] stringValue];

	//NSString* text = [NSString stringWithFormat:@"%@ (%@)", [dataDict valueForKey:@"Name"], [dataDict valueForKey:@"Count"]];
	//cell.textLabel.text = text;
	cell.selectionStyle = (UITableViewCellSelectionStyle) UITableViewCellSelectionStyleGray;

	[dataDict release];
	
    return cell;
}


#pragma mark CellNotificationDelegate

- (void) newSong: (NSInteger) offset
{
	self.indexPathOffset += offset;
}

- (void) startPlayback
{
	NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:self.indexPathSelected.row  + self.indexPathOffset inSection:self.indexPathSelected.section];
	SongCell* cell = (SongCell*) [(UITableView*) self.view cellForRowAtIndexPath:newIndexPath];
	cell.cached.image = [UIImage imageNamed:@"checked.png"];
}

- (void) trackPlayer:(NSIndexPath*) indexPath
{
	// track player commands here
	app.playerController.delegate = self;
	self.indexPathSelected = indexPath;
	self.indexPathOffset = 0;
}
@end
