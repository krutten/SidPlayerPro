//
//  SourceFavorites.m
//  ModPlayer
//
//  Created by Kai Teuber on 11.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SourceFavorites.h"


@implementation SourceFavorites

- (id) init
{
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (songPksInPlaylist != nil)
		[songPksInPlaylist release];

	songPksInPlaylist = [[NSMutableArray arrayWithArray: [[app database] getPlaylistSongPks:2]]retain];
	
	return self;
}

- (void) deleteSong: (NSInteger) songPk
{
	[[app database] delFavorite:songPk];
	NSNumber* removeNo = [[NSNumber numberWithInt:songPk]retain];
	[songPksInPlaylist removeObject:removeNo];
	[removeNo release];
}

- (BOOL) moveSongFromIndex:(NSInteger) from toIndex:(NSInteger) to
{
	if ( from == to ) return NO;
	NSLog(@"Move Song from Index %i to new Index %i", from, to);
	
	NSNumber* movedPK= [songPksInPlaylist objectAtIndex:from];

	if (from < to)
	{
		// move down
		[songPksInPlaylist insertObject:movedPK atIndex:to+1];
		[songPksInPlaylist removeObjectAtIndex:from];
	}
	else
	{
		// move up
		[songPksInPlaylist insertObject:movedPK atIndex:to];
		[songPksInPlaylist removeObjectAtIndex:from+1];
	}
	return YES;
}

@end
