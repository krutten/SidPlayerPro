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

#import "Random.h"
#include <stdlib.h>

@implementation Random

NSMutableArray* randomPKs;

- (void) randomize
{
	// init random PKs
	randomPKs = [[NSMutableArray alloc] init];
	int limit = [[app database] getHighestPK];
	for (int i = 1; i <=50; i++)
	{
		[randomPKs addObject:[[NSNumber alloc] initWithInteger:arc4random() % limit + 1]];
	}
}	

- (NSMutableArray*) getSongs
{
	if (randomPKs == nil)
	{
		[self randomize];
	}
	songsArray = [[app database] randomSongs];
	[songsArray removeAllObjects];
	// grab from PK list
	for ( int i = 1; i < 50 ; ++i )
	{
		//NSLog( @"creating song %d", i );
		int pk = [[randomPKs objectAtIndex:i] integerValue];
		Song* song = [[app database] getSongByPK:pk];
		assert( song != nil );
		if ([[app offlineMode] boolValue])
		{
			if ([song cached])
			{
				[songsArray addObject:song];
			}
		}
		else
		{
			[songsArray addObject:song];
		}
//		[song release];
	}
	
	return songsArray;
}

- (BOOL) rebuildViewNeeded
{
	BOOL refresh =  [[app database] rebuildRandomlist];
	[[app database] setRebuildRandomlist:NO];
	return refresh;
}

- (BOOL) shuffleMode
{
	return NO;
}

@end
