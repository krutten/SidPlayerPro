//
//  AuthorsViewController.m
//  ModPlayer
//
//  Created by Kai Teuber on 03.01.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "AuthorsViewController.h"
#import "SongsByAuthorViewController.h"

@implementation AuthorsViewController


- (void)viewWillAppear:(BOOL)animated
{
	if (app.database.authorsHaveChanged)
	{
		[app.database setAuthorsHaveChanged:NO];
		prefixCounted = nil;
		[self initModel];
		[(UITableView*)[self view] reloadData];
	}
}

// get counted prefixes for current author
-(NSArray*) getCountedArray
{
	if (!prefixCounted) prefixCounted = [[app database] prefixCountedByAuthors];
	return prefixCounted;
}


-(NSArray*) getNamesFrom:(NSInteger) start limitBy:(NSInteger) limit;
{
	return [[app database] getAuthorsStartAt:start limitBy:limit]; 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	SongsByAuthorViewController* targetViewController = [[SongsByAuthorViewController alloc] initWithNibName:@"SongsByAuthorViewController" bundle:nil];

	int requestId;
	requestId = [self getDbIndex: indexPath];
	
	NSDictionary* metaAuthor = [[[[app database] getAuthorsStartAt:requestId limitBy:1]objectAtIndex:0]retain];
	targetViewController.pkAuthor = [[metaAuthor valueForKey:@"id"]integerValue];

	NSString* pkAuthorStr = [[NSString stringWithFormat:@"%i", targetViewController.pkAuthor]retain];
	NSString* authorName = [[metaAuthor valueForKey:@"Name"]retain];
	
	[app setPkAuthor:pkAuthorStr];
	[app setAuthorName:authorName];
	
	NSLog(@"pkAuhtor set to: %i", targetViewController.pkAuthor);
	//	[targetViewController.navigationItem setTitle:authorName];
	[targetViewController.navigationItem setTitle:authorName];
	[self.navigationController pushViewController:targetViewController animated:YES];

	[targetViewController release];
	[pkAuthorStr release];
	[authorName release];
	[metaAuthor release];
}


- (void)dealloc {
	[prefixCounted release];
    [super dealloc];
}


@end

