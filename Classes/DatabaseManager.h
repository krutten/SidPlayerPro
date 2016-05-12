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

#import "BaseDatabase.h"
#import "Song.h"

@interface DatabaseManager : BaseDatabase {

	NSMutableArray*			searchSongsArray;
	NSThread*				searchTread;
	NSString*				searchText;
	NSInteger				searchStart;
	NSInteger				searchLimit;
	
	NSString*				stilText;
	NSInteger				highestPk;
	NSInteger				lastSongPK;

	id						callbackObj;
	BOOL					authorsHaveChanged;
	BOOL					rebuildCache;
	BOOL					searchMoreFound;
	BOOL					searchAppendResults;
	
	BOOL					searching;
}
@property (nonatomic, retain) NSMutableArray*	searchSongsArray;

@property (nonatomic, retain) NSThread*			searchTread;
@property (nonatomic, retain) NSString*			searchText;
@property (nonatomic) NSInteger					searchStart;
@property (nonatomic) NSInteger					searchLimit;

@property (nonatomic, copy)	NSString*			stilText;
@property (nonatomic) NSInteger					highestPk;
@property (nonatomic) NSInteger					lastSongPK;

@property (nonatomic) BOOL						authorsHaveChanged;
@property (nonatomic) BOOL						rebuildCache;
@property (nonatomic) BOOL						searchMoreFound;
@property (nonatomic) BOOL						searchAppendResults;
@property BOOL									searching;
@property (nonatomic, retain) id				callbackObj;


// search methods
- (void) initSearch;
- (void) searchSongsFor: (id)sender;

// -- Favorites stuff
- (void) toggleFavorite;
- (void) delFavorite: (int)pkSong;
- (void) addFavorite: (int)pkSong;
- (BOOL) isFavorite: (int)pkSong;
- (void) updatePosition: (int)newPosition forSong:(int)fkSong;
- (void) autoincrementPosition: (NSArray*) newPks;
- (void) deleteFavorite: (int)pkSong;

- (NSString*) getAuthor: (NSInteger) pkAuthor;
- (NSArray*) getSongsByAuthorWith:(NSInteger) pk startAt:(NSInteger)start limitBy:(NSInteger) limit;
- (NSString*) getSongInformationsByPK: (NSInteger) primaryKey;

// song helpers
- (Song*) getSongByPK: (NSInteger) primaryKey;
- (NSDictionary*) getSongdictByPK: (NSInteger) primaryKey;
- (BOOL) isSongAlreadyPlayed:(NSInteger)pkSong;
- (void) insertEmptySongPlayed: (NSInteger)pkSong;
- (void) markSongForCeck: (NSInteger) songId;
- (void) markSongAsCached: (NSInteger) songId;
- (void) addSongCount: (NSInteger) songId;
- (void) removePlayedEntries;
- (void) removeSongCount: (NSInteger) songId;

// download helpers
- (NSInteger) getFirstUncachedPK;
- (NSInteger) getHighestPK;

// playlist helpers
- (NSMutableArray*) getPlaylists: (NSString*) type;
- (NSArray*) getPlayedSongsPK;
- (NSArray*) getRandomSongsPK;
- (NSArray*) getPlaylistSongPks: (NSInteger) playlist;

// DB helpers
- (void) querieWithNoResult: (char*) sql;

// cache helpers
- (void) removeCachedEntries;
- (void) removeCachedCountOn: (NSString*) tablename;
- (void) removeCachedFlagOn: (NSString*) tablname;

// new listView methods
- (NSArray*) prefixCountedByAuthors;
- (NSArray*) getAuthorsStartAt:(NSInteger)start limitBy:(NSInteger) limit;
- (NSArray*) getSongsByAuthorWith:(NSInteger) pk startAt:(NSInteger)start limitBy:(NSInteger) limit;
- (NSArray*) songsCountedByAuthor:(NSInteger) pkAuthor;
- (NSArray*) getPkSongs: (NSInteger) pkAuthor;
- (void) insertEmptySongCacheCount: (NSInteger) pkAuthor;
- (NSInteger) getAuthorPk: (NSString*) authorname;
- (void) incrementAuthorCacheCount: (NSInteger) pkAuthor;
- (BOOL) isAuthorAlreadyCached:(NSInteger) pkAuthor;
- (void) markAuthorCached:(NSInteger) pkAuthor;
- (void) incrementSongCacheCount: (Song*)song;

@end
