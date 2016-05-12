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

#import "Datasource.h"

@implementation Datasource

@synthesize app;
@synthesize songsArray;

- (id) init
{
	[super init];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	return self;
}

- (NSMutableArray*) getSongs
{
	NSLog(@"Datasource: getSongs called - Error!");
	NSMutableArray* emptyPointer = nil;
	return emptyPointer;
}

- (void) deleteSong: (Song*) songToDelete
{
	[[app database] removeSongCount: [songToDelete primaryKey]];
	for (Song* currentSong in songsArray) {
		if (songToDelete == currentSong)
		{
			NSLog(@"Song to delete found!");
			[songsArray removeObject:currentSong];
			break;
		}
	}
}

- (BOOL) rebuildViewNeeded
{
	return NO;
}

- (BOOL) defaulCellType
{
	return YES;
}

- (BOOL) shuffleMode
{
	return YES;
}

- (void) shufflePlaylist
{
	NSLog(@"shufflePlaylist called");
}

@end
