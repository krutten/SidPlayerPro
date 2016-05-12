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
#import "AppDelegate.h"
#import "MultiSelectionViewController.h"

@interface SettingViewController : UITableViewController <UIActionSheetDelegate> {
	IBOutlet UITableView*			settingsTableView;
	
	NSArray*			settingsSections;

@private
	Sid_MachineAppDelegate*			app;
	MultiSelectionViewController*	sidModeMultiSelection;
	
}

@property (nonatomic, retain)	UITableView*					settingsTableView;
@property (nonatomic, retain)	NSArray*						settingsSections;

- (NSNumber*) getValue: (NSString*) objName;
// action methods
-(void)changedDefaultSongLengthSliding:(id)sender;
-(void)changedDefaultSongLengthDone:(id)sender;
-(void)changedPerformanceCheck:(id)sender;
-(void)changedOfflineMode:(id)sender;
-(void)changedOverrideSongLength:(id)sender;
-(void)changedAutomaticPlayNext:(id)sender;
-(void)changedNtscMode:(id)sender;
-(void)changedSidModeValue:(id)sender;

-(void)eraseDownloadCache;
-(void)erasePlayedSongs;

@end

@interface EraseDownloadCacheDelegate : NSObject <UIActionSheetDelegate> {} @end
@interface ErasePlayedSongsDelegate : NSObject <UIActionSheetDelegate> {} @end
