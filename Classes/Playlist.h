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

#import <UIKit/UIKit.h>
#import "Song.h"

@interface Playlist : NSObject {

	@private	NSMutableArray* pkPlaylist;
	@private	NSMutableArray*	currentPlaylist;

}

@property (nonatomic, retain) NSMutableArray*	currentPlaylist;
@property (nonatomic, retain) NSMutableArray*	pkPlaylist;

// set & delete a playlist
- (NSArray*)playlistPrimaryKeys;
- (void)deletePlaylist;
- (void)shuffleCurrentPlaylist;		// unusd for the moment

// load & save playlists
- (void)restorePlaylist: (NSArray*) primaryKeys;
- (void)setPlaylist: (NSMutableArray*) newPlaylist;
- (void)setPlaylistWithPKs: (NSArray*) newPlaylist;

// get song methods
- (Song*)previousSong;
- (Song*)nextSong;
- (Song*)songWithOffset: (NSInteger) offset;

@end
