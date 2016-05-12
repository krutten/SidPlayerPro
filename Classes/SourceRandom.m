//
//  SourceRandom.m
//  ModPlayer
//
//  Created by Kai Teuber on 11.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SourceRandom.h"
#import "AppDelegate.h"


@implementation SourceRandom


- (id) init
{
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (songPksInPlaylist != nil)
		[songPksInPlaylist release];
	
	if ( [app.offlineMode boolValue] )
	{
		songPksInPlaylist = [[NSMutableArray arrayWithArray: [[app database] getRandomSongsPK]]retain];
	}
	else
	{
		songPksInPlaylist = [[NSMutableArray alloc] init];
		int limit = [[app database] getHighestPK];
		for (int i = 1; i <=50; i++)
		{
			[songPksInPlaylist addObject:[NSNumber numberWithInt:arc4random() % limit + 1]];
		}
	}		
	
	return self;
}

- (void) deleteSong: (NSInteger) songPk
{
	// reset played count for song!
	NSNumber* removeNo = [[NSNumber numberWithInt:songPk]retain];
	[songPksInPlaylist removeObject:removeNo];
	[removeNo release];
}

@end
