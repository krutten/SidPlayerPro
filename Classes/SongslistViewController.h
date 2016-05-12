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
#import <sqlite3.h>

@interface SongslistViewController : UITableViewController {
	NSMutableArray*									songsArray;
	NSMutableDictionary*							indexedSongs;

	// arrays to store index and song names
	NSArray*										displayList;
	NSArray*										indexLetters;
}

@property (nonatomic, retain) NSMutableArray*		songsArray;
@property (nonatomic, retain) NSMutableDictionary*	indexedSongs;
@property (nonatomic, retain) NSArray*				displayList;
@property (nonatomic, retain) NSArray*				indexLetters;

- (IBAction)showPlayer:(id)sender;

@end
