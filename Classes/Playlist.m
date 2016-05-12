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

#import "Playlist.h"
#import "Song.h"
#import "AppDelegate.h"


@implementation Playlist

@synthesize currentPlaylist, pkPlaylist;

-(void)dealloc
{
	[currentPlaylist release];	// remove later!!
	[pkPlaylist	release];
	[super dealloc];
}

// uses an array with pks as playlist
- (void)setPlaylistWithPKs: (NSArray*) newPlaylist
{
	[self deletePlaylist];
	[self setPkPlaylist:[NSMutableArray arrayWithArray: newPlaylist]];
}

// uses an array with song objs as playlist - old version
-(void)setPlaylist: (NSMutableArray*) newPlaylist
{
	[self deletePlaylist];
	[self setCurrentPlaylist:[NSMutableArray arrayWithArray: newPlaylist]];
}


-(void)deletePlaylist
{
	[pkPlaylist removeAllObjects];
	[currentPlaylist removeAllObjects];
}


- (void) shuffleCurrentPlaylist
{
	// Fisher Yates shuffle alg. - switch by playlist
	int n;
	if ([currentPlaylist count] > 0)
	{
		n = [currentPlaylist count];
		while (n >1)
		{
			int rnd = arc4random() % n;
			int i = n -1;
			[currentPlaylist exchangeObjectAtIndex:i withObjectAtIndex:rnd];
			n--;
		}
	}
	else
	{
		n = [pkPlaylist count];
		while (n >1)
		{
			int rnd = arc4random() % n;
			int i = n -1;
			[pkPlaylist exchangeObjectAtIndex:i withObjectAtIndex:rnd];
			n--;
		}
	}		
}

// load a playlist by pk keys array
-(void)restorePlaylist: (NSArray*) primaryKeys
{
/*
	NSMutableArray* collectSongs = [[NSMutableArray alloc] init];
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	for (NSNumber* primaryKey in primaryKeys)
	{
		Song* newSong = [[appDelegate database] getSongByPK:[primaryKey integerValue]];
		[collectSongs addObject:newSong];
		[newSong release];
	}
	[self setPlaylist:collectSongs];
	[collectSongs release];
*/
}

// return an array with pk keys of current playlist - save playlist
-(NSArray*)playlistPrimaryKeys
{
	return [NSArray array];
	/*
	pkPlaylist = [NSMutableArray arrayWithCapacity:[currentPlaylist count]];
	for (Song* song in currentPlaylist)
	{
		NSNumber * myNumber = [NSNumber numberWithInt:[song primaryKey]];
		[pkPlaylist addObject:myNumber];
	}
	NSLog(@"%i Songs zum speichern bearbeite.", [pkPlaylist count]);
	return (NSArray*) pkPlaylist;
	*/
}

-(Song*)previousSong
{
	return [self songWithOffset:-1];
}

-(Song*)nextSong
{
	return [self songWithOffset:1];
}

- (Song*)songWithOffset: (NSInteger) offset
{
	NSArray* inspectPlaylist;
	if ([currentPlaylist count] > 0)
	{
		inspectPlaylist = currentPlaylist;
		if ( inspectPlaylist == nil )
		{
			NSLog(@"No playlist set");
			return nil;
		}
		Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
		NSUInteger currentIndex = [inspectPlaylist indexOfObject: [appDelegate currentSong]];
		
		assert( currentIndex != NSNotFound );
		
		if (offset < 0)
		{
			if ( currentIndex == 0 )
				return nil;
			else
				// TODO: check for possible crash here!
				NSAssert([inspectPlaylist count] > currentIndex + offset, @"old Playlist: Index out of bounds");
				return [inspectPlaylist objectAtIndex:currentIndex+offset];
			
		}
		else {
			if ( currentIndex == [inspectPlaylist count]-1 )
				return nil;
			else
				// TODO: check for possible crash here!
				NSAssert([inspectPlaylist count] > currentIndex + offset, @"old Playlist: Index out of bounds");
				return [inspectPlaylist objectAtIndex:currentIndex+offset];
		}
		
		
	}
	else
	{
		inspectPlaylist = pkPlaylist;

		if ( inspectPlaylist == nil )
		{
			NSLog(@"No playlist set");
			return nil;
		}
		Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
		NSNumber* currentPk = [NSNumber numberWithInt:[appDelegate currentSong].primaryKey];
		NSInteger currentIndex = [inspectPlaylist indexOfObject:currentPk];
		
		assert( currentIndex != NSNotFound );
		
		if (offset < 0)
		{
			if ( currentIndex == 0 )
				return nil;
			else
			{
				int index = currentIndex + offset;
				// TODO: check for possible crash here!
				NSAssert([inspectPlaylist count] > index, @"new Playlist: Index out of bounds");
				Song* nextSong = [[appDelegate database] getSongByPK: [[inspectPlaylist objectAtIndex:index]integerValue]];
				return nextSong;
			}
			
		}
		else {
			if ( currentIndex == [inspectPlaylist count]-1 )
				return nil;
			else
			{
				int index = currentIndex + offset;
				// TODO: check for possible crash here!
				NSAssert([inspectPlaylist count] > index, @"new Playlist: Index out of bounds");
				Song* nextSong = [[appDelegate database] getSongByPK: [[inspectPlaylist objectAtIndex:index]integerValue]];
				return nextSong;
			}
		}

	}

	
}

@end
