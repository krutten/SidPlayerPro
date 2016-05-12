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
@class Sid_MachineAppDelegate;
@class Song;
//#import "AppDelegate.h"


@interface SearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
	Sid_MachineAppDelegate*			app;
	IBOutlet UITableView*		myTableView;
	IBOutlet UISearchBar*		mySearchBar;
	NSMutableArray*				songsArray;
	BOOL						restartSeach;
	BOOL						ignoreResults;
	NSTimer*					myTimer;
	NSInteger					moreId;
	BOOL						appendSearchResults;
	
	CFAbsoluteTime				lastTapTime;
	NSUInteger					lastTapRow;
	BOOL						ignoreSelector;
}

@property (nonatomic, retain) UITableView*		myTableView;
@property (nonatomic, retain) UISearchBar*		mySearchBar;
@property (nonatomic, retain) NSMutableArray*	songsArray;
@property (nonatomic) BOOL						restartSeach;
@property (nonatomic) BOOL						ignoreResults;
@property (nonatomic) BOOL						ignoreSelector;
@property (nonatomic, retain) NSTimer*			myTimer;
@property (nonatomic) NSInteger					moreId;

-(void)rebuildTableView;
// private methods
-(void)startSearchByTimer:(NSTimer *)theTimer;
-(void)showSongsByAuthor:(Song*) newSong;
@end
