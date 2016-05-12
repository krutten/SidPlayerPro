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
@class Song;

#import "SongCacheConnection.h"
#import "PleaseWaitController.h"
#import "PlayerViewController.h"
#import "DatabaseManager.h"
#import "FileManager.h"
#import "Playlist.h"
#import "KeychainItemWrapper.h"


@interface Sid_MachineAppDelegate : NSObject
<
	UIApplicationDelegate,
	SongCacheConnectionDelegate,
	UIAlertViewDelegate
>
{
	NSString*						dataPath;
	NSError*						error;
	UIWindow*						window;
	IBOutlet UITabBarController*	myTabBarController;
	IBOutlet UIBarButtonItem*		downloadAllButton;
	BOOL							downloadInProgress;

	PleaseWaitController*			pleaseWaitController;
	PlayerViewController*			playerController;
	Song*							lastKnownSong;
	Song*							currentSong;
	Song*							nextSong;
	DatabaseManager*				database;
	FileManager*					filedb;
	Playlist*						playlist;

	NSString*					appName;
	NSString*					pkAuthor;
	NSString*					authorName;
	NSString*					lastSearch;

	NSNumber*					automaticPlayNext;
	NSNumber*					overrideSongLength;
	NSNumber*					offlineMode;
	NSNumber*					defaultSongLength;
	NSNumber*					forceNtscMode;
	NSNumber*					force8580Mode;
	NSNumber*					intSidMode;
	NSNumber*					firstStart;
	NSNumber*					enablePerformanceCheck;
	NSNumber*					enableOscillator;
	NSNumber*					pauseWhenLeavingPlayer;

	BOOL						restartSearch;
	BOOL						applicationRunningInBackground;
	
	KeychainItemWrapper*		wrapper;
}

@property (nonatomic, copy) NSString*								dataPath;

@property (nonatomic, retain) IBOutlet UIWindow*					window;
@property (nonatomic, retain) PleaseWaitController*					pleaseWaitController;
@property (nonatomic, retain) PlayerViewController*					playerController;
@property (nonatomic, retain) IBOutlet UITabBarController*			myTabBarController;
@property (nonatomic, retain) UIBarButtonItem*						downloadAllButton;
@property BOOL														downloadInProgress;

@property (nonatomic, retain) Song*									lastKnownSong;
@property (nonatomic, retain) Song*									currentSong;
@property (nonatomic, retain) Song*									nextSong;
@property (nonatomic, retain) DatabaseManager*						database;
@property (nonatomic, retain) FileManager*							filedb;
@property (nonatomic, retain) Playlist*								playlist;

@property (nonatomic, copy)	NSString*								appName;
@property (nonatomic, retain) NSString*								pkAuthor;
@property (nonatomic, retain) NSString*								authorName;
@property (nonatomic, retain) NSString*								lastSearch;

@property (nonatomic) BOOL											restartSearch;
@property (nonatomic) BOOL											applicationRunningInBackground;

@property (nonatomic, retain) NSNumber* automaticPlayNext;
@property (nonatomic, retain) NSNumber* overrideSongLength;
@property (nonatomic, retain) NSNumber* offlineMode;
@property (nonatomic, retain) NSNumber* defaultSongLength;
@property (nonatomic, retain) NSNumber* forceNtscMode;
@property (nonatomic, retain) NSNumber* intSidMode;
@property (nonatomic, retain) NSNumber* firstStart;
@property (nonatomic, retain) NSNumber* enablePerformanceCheck;
@property (nonatomic, retain) NSNumber* enableOscillator;
@property (nonatomic, retain) NSNumber* pauseWhenLeavingPlayer;

@property (retain) KeychainItemWrapper*	wrapper;
@property (assign, nonatomic) id mpNowPlayingInfoCenter;

@property (nonatomic, assign) BOOL      firstStartOfNewVersion;


-(void) alertCrackWithTracking:(BOOL)track;
-(void) deferredLaunching:(id)sender;
-(void) showSongslist: (NSInteger) pkToShow withName:(NSString*) authorName;

-(IBAction) downloadHVSC;
-(IBAction) showPlayer:(id)sender;
-(IBAction) showPlayerWithSong:(id)sender WithSong:(Song*)song;

-(void) showPlayerWithSong:(id)sender WithSong:(Song*)song pushPlayer:(BOOL)push;

-(void) restartCurrentSong;

-(void) AlertWithError:(NSError*)err;
-(void) AlertWithMessage:(NSString*)message;
-(void) AlertWithMessageAndDelegate:(NSString*)message WithDelegate:(id)delegate;

-(void) remoteControlReceivedWithEvent:(UIEvent*)event;
-(void) doPlayerAction:(NSString*)action;
//-(void) playSong:(NSString*)path;
-(void) playBufferedSong:(NSData*)buffer;
-(void) setVolume:(float)volume forVoice:(NSUInteger)voice;

-(short*) getSampleBuffer;

-(void) updatePlayerWindow;
-(void) updatePlaylist:(id)sender;

-(void) notifyOfflineMode;
-(void) eraseDownloadCache;
-(void) erasePlayedSongs;
-(void) eraseSongFile: (Song *)delSong;

@end

@interface DownloadHvscDelegateStart : NSObject <UIActionSheetDelegate> {} @end
@interface DownloadHvscDelegateStop : NSObject <UIActionSheetDelegate> {} @end
