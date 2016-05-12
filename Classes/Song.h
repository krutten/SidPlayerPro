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

#import <Foundation/Foundation.h>

@interface Song : NSObject {
	NSInteger	primaryKey;					// primary key of the song
	NSString*	name;						// name of the song
	NSString*	type;						// type of the song
	NSString*	authorName;					// name of author (optinal information)
	NSInteger   pkAuthor;					// pk of author, if known
	NSString*	uri;						// uri of filename
	NSInteger	duration;					// length of the default subsong (in seconds)
	NSInteger	playedCounter;				// how often a song got played
	BOOL		cached;						// indicate if a song is within the cache
	BOOL		problemFound;				// indicate there was once a problem with this song
	
	BOOL		favorite;					// indicate if song is member of favorites
}

@property (assign, nonatomic) NSInteger			primaryKey;
@property (retain, nonatomic) NSString*			name;
@property (retain, nonatomic) NSString*			type;
@property (retain, nonatomic) NSString*			authorName;
@property (assign, nonatomic) NSInteger			pkAuthor;
@property (retain, nonatomic) NSString*			uri;
@property (assign, nonatomic) NSInteger			duration;
@property (assign, nonatomic) NSInteger			playedCounter;
@property (assign, nonatomic) BOOL				cached;
@property (assign, nonatomic) BOOL				problemFound;

@property (assign, nonatomic) BOOL				favorite;

@end
