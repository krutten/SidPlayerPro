//
//  SourceTop100.m
//  SidPlayerPro
//
//  Created by Kai Teuber on 04.03.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SourceTop100.h"


@implementation SourceTop100

- (id) init
{
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (songPksInPlaylist != nil)
		[songPksInPlaylist release];
	
	songPksInPlaylist = [[NSMutableArray arrayWithArray: [[app database] getPlaylistSongPks:4]]retain];
	
	return self;
}

- (void) deleteSong: (NSInteger) songPk
{
	[[app database] delFavorite:songPk];
	NSNumber* removeNo = [[NSNumber numberWithInt:songPk]retain];
	[songPksInPlaylist removeObject:removeNo];
	[removeNo release];
}


@end
