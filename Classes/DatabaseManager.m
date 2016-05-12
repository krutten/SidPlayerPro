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

#import "DatabaseManager.h"
#import "Song.h"
#import "SearchViewController.h"
#import "AppDelegate.h"

@interface DatabaseManager ()

- (void) searchThread:(id)info;

@end

@implementation DatabaseManager

Sid_MachineAppDelegate*		app;

@synthesize authorsHaveChanged;

@synthesize searchSongsArray;
@synthesize searchTread;
@synthesize searchText;
@synthesize searchStart;
@synthesize searchLimit;
@synthesize stilText;
@synthesize	highestPk;
@synthesize lastSongPK;
@synthesize searchMoreFound;
@synthesize searchAppendResults;
@synthesize rebuildCache;

@synthesize searching;
@synthesize callbackObj;

- (void)dealloc {
    [super dealloc];
	[searchSongsArray release];
	[searchText release];
	[stilText release];
}



#pragma mark -
#pragma mark public methods
#pragma mark -

- (void)initDatabase: (NSString*)dbToName
{
	[super initDatabase:dbToName];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];

	// The database is stored in the application bundle.
	searchSongsArray = [[NSMutableArray alloc] init];
	[self initSearch];
	
}

- (void) initSearch
{
	// set search start value & limit
	searchStart = 0;
	searchLimit = 25;
	searchAppendResults = NO;
	searchMoreFound = NO;
}

#pragma mark Favorites Helpers

- (void) toggleFavorite
{
	Song* current = [app currentSong];
	if (!current) return;
	NSLog(@"Change state of favorite state - song %@", [current name]);
	if ([self isFavorite:[current primaryKey]])
	{
		NSLog(@" -> remove song from favorites");
		[self delFavorite:[current primaryKey]];
//		[self setRebuildFavorites:YES];
	}
	else
	{
		NSLog(@" -> add song to favorites");
		[self addFavorite:[current primaryKey]];
//		[self setRebuildFavorites:YES];
	}
}

- (void) delFavorite: (int)pkSong
{
	[self openDatabase];
	
	// Get the primary key for all books.
	const char *sql = "DELETE FROM SongsInPlaylists WHERE fkPlaylist = 2 AND fkSong = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
		[[app currentSong] setFavorite:NO];
	}
	[theLock unlock];
}

- (void) addFavorite: (int)pkSong
{
	[self openDatabase];
	
	// Get the primary key for all books.
	const char *sql = "INSERT INTO SongsInPlaylists (Position, fkPlaylist, fkSong) \
						VALUES ( (SELECT COUNT(Position)+1 FROM SongsInPlaylists WHERE fkPlaylist = 2), 2, ?)";
	sqlite3_stmt *statement;
	[theLock lock];
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
		[[app currentSong] setFavorite:YES];
	}
	[theLock unlock];
}

- (BOOL) isFavorite: (int)pkSong
{
	[self openDatabase];
	
	// Get the primary key for all books.
	const char *sql = "SELECT COUNT(Position) FROM SongsInPlaylists WHERE fkPlaylist = 2 AND fkSong = ?" ;
	sqlite3_stmt *statement;
	[theLock lock];
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		int countPosition = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);

		[[app currentSong] setPrimaryKey: pkSong];
		[[app currentSong] setFavorite:(BOOL) countPosition];
		lastSongPK =  pkSong;
	}
	[theLock unlock];
	return [[app currentSong] favorite];
}

- (void) updatePosition: (int)newPosition forSong:(int)fkSong
{
	[self openDatabase];
	
	// Get the primary key for all books.
	const char *sql = "UPDATE SongsInPlaylists SET Position = ? WHERE fkPlaylist = 2 AND fkSong = ?" ;
	sqlite3_stmt *statement;
	[theLock lock];
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, newPosition);
		sqlite3_bind_int(statement, 2, fkSong);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
}

- (void) autoincrementPosition: (NSArray*) newPks
{
	int position = 1;
	
	for (NSNumber* songPk in newPks)
	{
		[self updatePosition:position forSong:[songPk intValue]];
		position++;
	}
}

- (void) deleteFavorite: (int)pkSong
{
	NSLog(@"try to remove Song with ID:%i from favorites", pkSong);
	[self openDatabase];
	// Get the primary key for all books.
	const char *sql = "DELETE FROM SongsInPlaylists WHERE fkPlaylist = 2 AND fkSong = ?";
	int countedSongs = 0;
	sqlite3_stmt *statement;
	[theLock lock];
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		countedSongs = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	// TODO: check if really needed!
//	[self autoincrementPosition:[self getFavoriteSongs]];
}


// TODO: fix for Sid Player
/*
- (NSMutableArray*) getTop65Songs {
	[self openDatabase];
	
	[skytopiaTop65 removeAllObjects];
	// Get the primary key for all books.
	const char *sql;
	if ( [app.offlineMode boolValue] )
		sql = "SELECT S.ID, S.fkAuthor, S.Name, S.URI, S.Duration, S.PlayedCounter, S.Cached, S.ProblemsFound FROM SongsInPlaylists as PL JOIN Songs AS S ON PL.fkSong = S.ID WHERE S.Cached = 'TRUE' AND PL.fkPlaylist = 5 ORDER BY PL.Position;";
	else
		sql = "SELECT S.ID, S.fkAuthor, S.Name, S.URI, S.Duration, S.PlayedCounter, S.Cached, S.ProblemsFound FROM SongsInPlaylists as PL JOIN Songs AS S ON PL.fkSong = S.ID WHERE PL.fkPlaylist = 5 ORDER BY PL.Position;";
	
	sqlite3_stmt *statement;
	[theLock lock];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) {
			// The second parameter indicates the column index into the result set.
			int primaryKey = sqlite3_column_int(statement, 0);
			int pkAuthor = sqlite3_column_int(statement, 1);
			NSString* Name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
			NSString* URI = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
			int duration = sqlite3_column_int(statement, 4);
			int playedCounter = sqlite3_column_int(statement, 5);
			const char* c = sqlite3_column_blob(statement, 6);
			bool cached = (c[0] == 'T');
			const char* p = sqlite3_column_blob(statement, 7);
			bool probelm = (p[0] == 'T');
			
			Song* newSong = [[Song alloc]init];
			[newSong setName:Name];
			[newSong setPrimaryKey:primaryKey];
			[newSong setUri:URI];
			[newSong setDuration:duration];
			[newSong setPlayedCounter:playedCounter];
			[newSong setCached: (bool) cached];
			[newSong setProblemFound: (bool) probelm];
#ifdef SIDPLAYER
#else
			[newSong setAuthorName:[self getAuthor:pkAuthor]];
#endif
			
			[skytopiaTop65 addObject:newSong];
			[newSong release];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return skytopiaTop65;
}

*/

#pragma mark -

- (NSString*) getSongInformationsByPK: (NSInteger) primaryKey
{
	[self openDatabase];
	
	const char *sql = "SELECT STIL FROM Songs WHERE ID = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, primaryKey);
		sqlite3_step(statement);
		self.stilText = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)] ;
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return self.stilText;
}

- (NSString*) getAuthor: (NSInteger) pkAuthor {
	[self openDatabase];
	const char* sql;
	sql = "SELECT Name FROM Authors WHERE ID = ?";
	sqlite3_stmt *statement;
	NSString* authorName;
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			authorName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		}
	}
	sqlite3_finalize(statement);
	return authorName;
}

- (NSArray*) songsCountedByAuthor:(NSInteger) pkAuthor
{
	[self openDatabase];
	const char* sql;
	
	if ( [app.offlineMode boolValue] )
		sql = "SELECT * FROM SongsCachedCounted Where fkAuthor = ?";
	else
		sql = "SELECT * FROM SongsCounted Where fkAuthor = ?";
	
	sqlite3_stmt *statement;
	NSMutableArray* myData = [NSMutableArray array];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			for (int i = 0; i<27; i++) {
				int value = sqlite3_column_int(statement, i);
				[myData addObject:[NSNumber numberWithInteger:value]];
			}
		}
	}
	sqlite3_finalize(statement);
	return myData;
}

- (NSArray*) prefixCountedByAuthors
{
	[self openDatabase];
	const char* sql;
	
	if ([app.offlineMode boolValue])
		sql = "SELECT * FROM AuthorsCachedCounted";
	else
		sql = "SELECT * FROM AuthorsCounted";
	sqlite3_stmt *statement;
	NSMutableArray* myData = [NSMutableArray array];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			for (int i = 0; i<27; i++) {
//				NSLog(@"try to get value for %i", i);
				int value = sqlite3_column_int(statement, i);
				[myData addObject:[NSNumber numberWithInteger:value]];
			}
		}
	}
	sqlite3_finalize(statement);
	return myData;
}

#pragma mark Playlist Helpers

- (NSMutableArray*) getPlaylists: (NSString*) type
{
	[self openDatabase];
	NSMutableArray* playlistsArray = [[NSMutableArray alloc] init];
	
    // Get all playlists
    const char *sql;
	sql = "SELECT ID, Name FROM Playlists WHERE Type=? ORDER BY Position";
	
    sqlite3_stmt *statement;
	
	[theLock lock];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_text(statement, 1, [type UTF8String] , -1, SQLITE_STATIC);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			
			int playlistId = sqlite3_column_int(statement, 0);
			NSString* playlistName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
			[playlistsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSString stringWithFormat: @"%i", playlistId], @"idPlaylist",
									   playlistName, @"playlistName",
									   nil]];
		}
	}
    sqlite3_finalize(statement);
	[theLock unlock];
	return playlistsArray;
}

- (NSArray*) getPlayedSongsPK
{
	[self openDatabase];
	
	const char* sql;

	if ( [app.offlineMode boolValue] )
	{
		sql = "SELECT p.fkSong FROM SongsPlayed AS p JOIN SONGS as s ON p.fkSong = s.id WHERE s.Cached = 'TRUE' ORDER BY p.Counted DESC";
	}
	else
	{
		sql = "SELECT fkSong FROM SongsPlayed ORDER BY Counted DESC";
	}
	
	NSMutableArray* result = [NSMutableArray array];
	
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSNumber* songPk = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
			[result addObject: songPk];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return result;
}

- (NSArray*) getPlaylistSongPks: (NSInteger) playlist
{
	[self openDatabase];
	
	const char* sql;
	if ( [app.offlineMode boolValue] )
	{
		sql = "SELECT fkSong FROM SongsInPlaylists AS p JOIN SONGS AS s on p.fkSong = s.id WHERE p.fkPlaylist = ? AND s.Cached = 'TRUE' ORDER BY Position ASC;";
	}
	else {
		sql = "SELECT fkSong FROM SongsInPlaylists WHERE fkPlaylist = ? ORDER BY Position ASC;";
	}
	
	NSMutableArray* result = [NSMutableArray array];
	
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_int(statement, 1, playlist);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSNumber* songPk = [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)]retain];
			[result addObject: songPk];
			[songPk release];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return result;
	
}

- (NSArray*) getRandomSongsPK
{
	[self openDatabase];
	
	const char* sql;
	sql = "SELECT ID FROM Songs WHERE Cached = 'TRUE' ORDER BY RANDOM() LIMIT 0,50";
	NSMutableArray* result = [NSMutableArray array];
	
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSNumber* songPk = [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)]retain];
			[result addObject: songPk];
			[songPk release];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return result;
}


#pragma mark -

/* will load a group of AuthorNames */
-(NSArray*) getAuthorsStartAt:(NSInteger)start limitBy:(NSInteger) limit
{
	[self openDatabase];
	NSMutableArray* results = [NSMutableArray array];
	const char* sql;
	if ([app.offlineMode boolValue])
		sql = "SELECT ID, Name, SongCount FROM Authors WHERE Cached = 'TRUE' ORDER By Name LIMIT ?,?";
	else
		sql = "SELECT ID, Name, SongCount FROM Authors ORDER By Name LIMIT ?,?";
	
	sqlite3_stmt *statement;
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, start);
		sqlite3_bind_int(statement, 2, limit);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			NSNumber* idAuthor = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
			NSString* name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
			NSNumber* count = [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];

			NSDictionary* dataset = [[NSDictionary dictionaryWithObjectsAndKeys:
									  idAuthor, @"id",
									  name, @"Name",
									  count, @"Count",
									  nil] retain];
			
			[results addObject:dataset];
			[dataset release];
		}
	}
	sqlite3_finalize(statement);
	return results;
}

/* will load a group of Songs */
-(NSArray*) getSongsByAuthorWith:(NSInteger) pk startAt:(NSInteger)start limitBy:(NSInteger) limit
{
	[self openDatabase];
	NSMutableArray* results = [NSMutableArray array];
	const char* sql;
	if ( [app.offlineMode boolValue] )
	{
		sql = "SELECT ID, Name, Cached, Type FROM Songs WHERE fkAuthor = ? AND Cached = 'TRUE' ORDER By Name LIMIT ?,?";
	}
	else
	{
		sql = "SELECT ID, Name, Cached, Type FROM Songs WHERE fkAuthor = ? ORDER By Name LIMIT ?,?";
	}
	
	sqlite3_stmt *statement;
	
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pk);
		sqlite3_bind_int(statement, 2, start);
		sqlite3_bind_int(statement, 3, limit);
		
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSNumber* idSong = [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)]retain];
			NSString* name = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)]retain];
			const char* c = sqlite3_column_blob(statement, 2);
			NSNumber* cached = [[NSNumber numberWithBool:(c[0] == 'T')]retain];
			NSString* type = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)]retain];			

			NSDictionary* dataset = [[NSDictionary dictionaryWithObjectsAndKeys:
									  idSong, @"id",
									  name, @"Name",
									  type, @"Type",
									  cached, @"Cached",
									  nil] retain];
			
			[results addObject:dataset];
			[cached release];
			[name release];
			[type release];
			[idSong release];
			[dataset release];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return results;
}

- (NSArray*) getPkSongs: (NSInteger) pkAuthor
{
	[self openDatabase];
	
	const char* sql;
	if ( [app.offlineMode boolValue] ) {
		sql = "SELECT ID FROM Songs WHERE fkAuthor = ? AND Cached = 'TRUE'";
	}
	else
	{
		sql = "SELECT ID FROM Songs WHERE fkAuthor = ?";
	}
	
	NSMutableArray* result = [NSMutableArray array];
	
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			NSNumber* songPk = [[NSNumber numberWithInt:sqlite3_column_int(statement, 0)]retain];
			[result addObject: songPk];
			[songPk release];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return result;
}


- (void) insertEmptySongCacheCount: (NSInteger) pkAuthor
{
	[self openDatabase];
	const char* sql = "INSERT INTO SongsCachedCounted \
	(Rest, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, fkAuthor) \
	VALUES (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,?)";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
}

- (void) insertEmptyAuthorCacheCount
{
	[self openDatabase];
	const char* sql = "INSERT INTO AuthorsCachedCounted \
	(Rest, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z) \
	VALUES (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
}


- (NSInteger) getAuthorPk: (NSString*) authorname
{
	[self openDatabase];
	const char* sql;
	sql = "SELECT ID FROM Authors WHERE NAME = ?";
	sqlite3_stmt *statement;
	NSInteger authorPk;
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_text(statement, 1, [authorname UTF8String], -1, SQLITE_STATIC);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			authorPk = sqlite3_column_int(statement, 0);;
		}
	}
	sqlite3_finalize(statement);
	return authorPk;
}

// count a song that's new within the cache
- (void) incrementAuthorCacheCount: (NSInteger) pkAuthor
{
	NSString* firstLetter	= [[[self getAuthor:pkAuthor] substringToIndex:1].uppercaseString retain];
	
	if([firstLetter caseInsensitiveCompare:@"A"] == NSOrderedAscending ||
	   [firstLetter caseInsensitiveCompare:@"Z"] == NSOrderedDescending)  {
		firstLetter = @"Rest";
	}

	[self openDatabase];

	NSString* sqlString = [[NSString stringWithFormat:@"UPDATE AuthorsCachedCounted SET %@ = %@ +1;", firstLetter, firstLetter]retain];
	char sql[1000];
	[sqlString getCString:sql];
	[sqlString release];
	
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[firstLetter release];
	[theLock unlock];
}

- (BOOL) isAuthorAlreadyCached:(NSInteger)pkAuthor
{
	const char* sql;
	sql = "SELECT Cached FROM Authors WHERE ID = ?;";
	
	sqlite3_stmt *statement;
	BOOL result;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		while (sqlite3_step(statement) == SQLITE_ROW) {
			const char* c = sqlite3_column_blob(statement, 0);
			result = (c[0] == 'T');
		}
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	return result;
}

- (void) markAuthorCached:(NSInteger) pkAuthor
{
	const char* sql;
	sql = "UPDATE Authors SET Cached = 'TRUE' WHERE ID = ?;";

	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
}

// count a song that's new within the cache
- (void) incrementSongCacheCount: (Song*)song
{
	int pkAuthor = [self getAuthorPk: song.authorName];
	if (![self isAuthorAlreadyCached:pkAuthor])
	{
		[self markAuthorCached:pkAuthor];
		[self incrementAuthorCacheCount:pkAuthor];
	}
	
	NSArray* counted = [[self songsCountedByAuthor: pkAuthor]retain];
	if ([counted count] < 28)
	{
		NSLog(@"We need to insert initial data to the CacheCountTable");
		[self insertEmptySongCacheCount: pkAuthor];
	}
	[counted release];


	NSString* firstLetter	= [[song.name substringToIndex:1].uppercaseString retain];
	
	if([firstLetter caseInsensitiveCompare:@"A"] == NSOrderedAscending ||
	   [firstLetter caseInsensitiveCompare:@"Z"] == NSOrderedDescending)  {
		firstLetter = @"Rest";
	}

	[self openDatabase];

	NSString* sqlString = [[NSString stringWithFormat:@"UPDATE SongsCachedCounted SET %@ = %@ +1 WHERE fkAuthor = ?;", firstLetter, firstLetter]retain];
	char sql[1000];
	[sqlString getCString:sql];
	[sqlString release];

	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkAuthor);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
	}
	[firstLetter release];
	[theLock unlock];
}


#pragma mark Download helpers

- (NSInteger) getFirstUncachedPK
{
	[self openDatabase];
	const char *sql = "SELECT ID FROM Songs WHERE Cached = 'FALSE' LIMIT 1";
	int primaryKey = 0;
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		primaryKey = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	return primaryKey;
}

- (NSInteger)getHighestPK
{
	if (!highestPk)
	{
		[self openDatabase];
		const char *sql = "SELECT MAX(ID) FROM SONGS";
		sqlite3_stmt *statement;
		[theLock lock];
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
			sqlite3_step(statement);
			highestPk = sqlite3_column_int(statement, 0);
			sqlite3_finalize(statement);
		}
		[theLock unlock];
	}
	return highestPk;
}

#pragma mark SongHelpers

- (NSDictionary*) getSongdictByPK: (NSInteger) primaryKey
{
	[self openDatabase];
	NSDictionary* dataset;
	// lets build a matching querie
	const char* sql;
	
//	if ( [app.offlineMode boolValue] )
//	{
//		sql = "SELECT ID, Name, Cached, Type FROM Songs WHERE ID = ? AND Cached = 'TRUE';";
//	}
//	else
//	{
		sql = "SELECT ID, Name, Cached, Type FROM Songs WHERE ID = ?;";
//	}
	
	sqlite3_stmt *statement;
	
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_int(statement, 1, primaryKey);
		
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			NSNumber* idSong = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
			NSString* name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
			const char* c = sqlite3_column_blob(statement, 2);
			NSNumber* cached = [NSNumber numberWithBool:(c[0] == 'T')];
			NSString* type = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];			

			dataset = [NSDictionary dictionaryWithObjectsAndKeys:
								 idSong, @"id",
								 name, @"Name",
								 cached, @"Cached",
								 type, @"Type",
								 nil];
			
//			[dataset retain];
		}
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return dataset;
}

- (Song*) getSongByPK: (NSInteger) primaryKey
{
	[self openDatabase];
	
	const char *sql = "SELECT ID, fkAuthor, Name, URI, Duration, PlayedCounter, Cached, ProblemsFound, Type FROM SONGS WHERE ID = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	Song* newSong = [[Song alloc] init];

	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, primaryKey);
		sqlite3_step(statement);

		int primaryKey = sqlite3_column_int(statement, 0);
		int pkAuthor = sqlite3_column_int(statement, 1);
		NSString* Name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
		NSString* URI = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
		int duration = sqlite3_column_int(statement, 4);
		int playedCounter = sqlite3_column_int(statement, 5);
		const char* c = sqlite3_column_blob(statement, 6);
		bool cached = (c[0] == 'T');
		const char* p = sqlite3_column_blob(statement, 7);
		bool probelm = (p[0] == 'T');
		NSString* Type = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 8)];

		[newSong setName:Name];
		[newSong setType:Type];
		[newSong setPrimaryKey:primaryKey];
		[newSong setPkAuthor:pkAuthor];
		[newSong setUri:URI];
		[newSong setDuration:duration];
		[newSong setPlayedCounter:playedCounter];
		[newSong setCached: (bool) cached];
		[newSong setProblemFound: (bool) probelm];
		[newSong setAuthorName:[self getAuthor:pkAuthor]];
	}
	sqlite3_finalize(statement);
	[theLock unlock];
	return newSong;
}

- (BOOL) isSongAlreadyPlayed:(NSInteger)pkSong
{
	const char* sql;
	sql = "SELECT COUNT(Counted) FROM SongsPlayed WHERE fkSong = ?;";
	
	sqlite3_stmt *statement;
	BOOL result;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		int counted = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
		result = (counted > 0);
	}
	[theLock unlock];
	return result;
}

- (void) insertEmptySongPlayed: (NSInteger)pkSong
{
	[self openDatabase];
	const char *sql = "INSERT INTO SongsPlayed (fkSong, Counted) VALUES (?,0)";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}

- (void) markSongForCeck: (NSInteger) songId
{
	[self openDatabase];
	const char *sql = "UPDATE Songs SET ProblemsFound = 'TRUE' WHERE ID = ?" ;
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, songId);
		
		sqlite3_step(statement);
		sqlite3_finalize(statement);
		self.rebuildCache = YES; // change Chaching state
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}

- (void) markSongAsCached: (NSInteger) pkSong {
	[self openDatabase];
	const char *sql = "UPDATE Songs SET Cached='TRUE' WHERE ID = ?" ;
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);

		sqlite3_step(statement);
		sqlite3_finalize(statement);
//		self.rebuildCache = YES; // change Chaching state
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}

- (void) addSongCount: (NSInteger) pkSong {
	NSLog(@"playedCounter++");
	if (! [self isSongAlreadyPlayed: pkSong])
		[self insertEmptySongPlayed: pkSong];
	
	[self openDatabase];
	const char *sql = "UPDATE SongsPlayed Set Counted = Counted + 1 WHERE fkSong = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pkSong);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}


- (void)removePlayedEntries
{
	[self openDatabase];
	const char* sql = "DELETE FROM SongsPlayed";
	sqlite3_stmt* statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		sqlite3_finalize(statement);
//		self.rebuildPlayedlist = YES;
	}
	
	[theLock unlock];
}

- (void) removeSongCount: (NSInteger) songId
{
	[self openDatabase];
	const char* sql = "DELETE FROM SongsPlayed WHERE fkSong = ?";
	sqlite3_stmt* statement;
	[theLock lock];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, songId);
		sqlite3_step(statement);
		sqlite3_finalize(statement);
		self.rebuildCache = YES;
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}

#pragma mark DB Helpers

- (void) querieWithNoResult: (char*) sql
{
	[self openDatabase];
	sqlite3_stmt* statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		sqlite3_finalize(statement);
//		self.rebuildCache = YES;
//		self.rebuildPlayedlist = YES;
	}
	[theLock unlock];
}


#pragma mark CacheHelpers

- (void)removeCachedEntries
{
	[self removeCachedFlagOn: @"Authors"];
	[self removeCachedCountOn: @"Authors"];
	[self removeCachedFlagOn: @"Songs"];
	[self removeCachedCountOn: @"Songs"];
}

- (void) removeCachedCountOn: (NSString*) tablename
{
	NSString* sqlquery = [NSString stringWithFormat:@"UPDATE %@CachedCounted SET Rest=0, A=0, B=0, C=0, D=0, E=0, F=0, G=0, H=0, I=0, J=0, K=0, L=0, M=0, N=0, O=0, P=0, Q=0, R=0, S=0, T=0, U=0, V=0, W=0, X=0, Y=0, Z=0", tablename];
	char sql[1000];
	[sqlquery getCString:sql];
	// send querie to db
	[self querieWithNoResult: sql];
}

- (void) removeCachedFlagOn: (NSString*) tablename
{
	NSString* sqlquery = [NSString stringWithFormat:@"UPDATE %@ SET Cached='FALSE'", tablename];
	char sql[1000];
	[sqlquery getCString:sql];
	// send querie to db
	[self querieWithNoResult: sql];
}


#pragma mark searchHelpers

- (void) searchSongsFor: (id)sender
{
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[self setSearchText:[appDelegate lastSearch]];
	[self setCallbackObj:sender];

	if (searching == NO) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		NSThread *searchThread = [[NSThread alloc] initWithTarget:self selector:@selector(searchThread:) object:nil];
		self.searchTread = searchThread;
		[searchThread release];

		[searchTread start];
	}
	else
	{
		NSLog(@"we need to restart search, when last search finished!");
		[sender setRestartSeach:YES];
	}
}



#pragma mark -
#pragma mark private methods
#pragma mark -
- (void) searchThread:(id)info
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[self setSearchText:[appDelegate lastSearch]];

    // Lower search thread priority for glitch-free audio
    [NSThread setThreadPriority:0.6];

	[self setSearching:YES];

	[self openDatabase];
	NSMutableArray* tmpSearchArray = [[NSMutableArray alloc] init];
	const char* sql;
	if ( [app.offlineMode boolValue] )
		sql = "SELECT a.ID, a.fkAuthor, a.Name, a.URI, a.Duration, a.Cached, a.ProblemsFound, b.Name, a.Type FROM Songs AS a JOIN Authors AS b ON a.fkAuthor = b.ID WHERE a.Cached = 'TRUE' AND (a.Name LIKE ?001 OR b.Name Like ?002) LIMIT ?,?";
	else
		sql = "SELECT a.ID, a.fkAuthor, a.Name, a.URI, a.Duration, a.Cached, a.ProblemsFound, b.Name, a.Type FROM Songs AS a JOIN Authors AS b ON a.fkAuthor = b.ID WHERE a.Name LIKE ?001 OR b.Name Like ?002 LIMIT ?,?";

	if (self.searchAppendResults)
		self.searchStart += self.searchLimit;

	NSLog(@"Search starts at: %i", self.searchStart);
	
	sqlite3_stmt *statement;
	NSString *wildcardSearch = [NSString stringWithFormat:@"%%%@%%", [self searchText]];

	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_text(statement, 1, [wildcardSearch UTF8String], -1, SQLITE_STATIC);
		sqlite3_bind_text(statement, 2, [wildcardSearch UTF8String], -1, SQLITE_STATIC);
		// bind the limits here
		sqlite3_bind_int(statement, 3, searchStart);
		sqlite3_bind_int(statement, 4, searchLimit + 1);

		NSInteger	count = 0;
		searchMoreFound = NO;
		while (sqlite3_step(statement) == SQLITE_ROW) {
			count++;
			if (count <= searchLimit)
			{
				int primaryKey = sqlite3_column_int(statement, 0);
				int pkAuthor = sqlite3_column_int(statement, 1);
				NSString* Name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
				NSString* URI = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
				int duration = sqlite3_column_int(statement, 4);
				const char* c = sqlite3_column_blob(statement, 5);
				bool cached = (c[0] == 'T'); 
				const char* p = sqlite3_column_blob(statement, 6);
				bool probelm = (p[0] == 'T');
				NSString* authorName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 7)];
				NSString* Type = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 8)];
				
				Song* newSong = [[Song alloc]init];
				[newSong setName:Name];
				[newSong setType:Type];
				[newSong setPrimaryKey:primaryKey];
				[newSong setUri:URI];
				[newSong setDuration:duration];
				[newSong setAuthorName:authorName];
				[newSong setPkAuthor:pkAuthor];
				[newSong setCached: (bool) cached];
				[newSong setProblemFound: (bool) probelm];
				[newSong setAuthorName:[self getAuthor:pkAuthor]];
				
				[tmpSearchArray addObject:newSong];
				[newSong release];
			}
			else
			{
				NSLog(@"Search found more - set indicator");
				searchMoreFound = YES;
			}
		}
	}
	sqlite3_finalize(statement);
	NSLog(@"search did finish and found %i", [tmpSearchArray count]);
	[theLock unlock];

	if (! searchAppendResults)
		[[self searchSongsArray] removeAllObjects];
	[[self searchSongsArray] addObjectsFromArray: tmpSearchArray];

	[tmpSearchArray release];
	[self setSearching:NO];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// callback SearchViewController
	[(SearchViewController*)[self callbackObj] rebuildTableView];
    [pool release];
}

@end
