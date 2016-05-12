//
//  SourceTop50.m
//  ModPlayer
//
//  Created by Kai Teuber on 05.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SourceTop50.h"
#import "AppDelegate.h"

@implementation SourceTop50

@synthesize refreshNeeded;


- (void)dealloc
{
	[songPksInPlaylist release];
	[super dealloc];
}


- (id) init
{
	[super init];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (songPksInPlaylist != nil)
		[songPksInPlaylist release];
	songPksInPlaylist = [[NSMutableArray arrayWithArray:[[app database] getPlayedSongsPK]]retain];
	return self;
}

- (NSInteger) countedSongs
{
	if (songPksInPlaylist == nil)
		return 0;
	else
		return [songPksInPlaylist count];
}

- (NSArray*) getSongNames:(NSInteger) start limitBy:(NSInteger) limit;
{
	NSMutableArray* result = [NSMutableArray array];
	NSInteger end = start + limit;
	if ([songPksInPlaylist count] < end)
	{
		end = [songPksInPlaylist count]%limit + start;
	}
	
	
	for (int i = start; i < end; i++)
	{
		NSInteger pk = [[songPksInPlaylist objectAtIndex:i]intValue];
		NSDictionary* data = [[[app database] getSongdictByPK:pk]retain];
		[result addObject:data];
		[data release];
	}
	
	return result;
}

- (NSArray*) getPlaylistPKs
{
	return songPksInPlaylist;
}


- (void) deleteSong: (NSInteger) songPk
{
	// reset played count for song!
	NSLog(@"Delesong with ID %i from Top50 Playlist", songPk);
	[[app database] removeSongCount:songPk];
	NSNumber* removeNo = [[NSNumber numberWithInt:songPk]retain];
	[songPksInPlaylist removeObject:removeNo];
	[removeNo release];
}


- (void) shufflePlaylist
{
	NSLog(@"Shuffle Top Playlist");
	NSMutableArray* currentSongs = songPksInPlaylist;
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
@end
