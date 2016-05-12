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

unsigned int SIDPLAYER_APP_VERSION = 2957;

extern "C" {

NSInteger LT_systemVersionAsInteger()
{
    int index = 0;
    NSInteger version = 0;
    
    NSArray* digits = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSEnumerator* enumer = [digits objectEnumerator];
    NSString* number;
    while (number = [enumer nextObject]) {
        if (index>2) {
            break;
        }
        NSInteger multipler = powf(100, 2-index);
        version += [number intValue]*multipler;
        index++;
    }
    return version;
}
}

#define null NULL;

#define DRIVER_PERFORMANCE_THRESHOLD 1

#ifdef SIDPLAYERPRO
  #define HVSC_INDEX_DATABASE		@"hvsc56index.sql"
#else
 #define HVSC_INDEX_DATABASE		@"hvsc52index.sql"
#endif

#ifdef ATARIPLAYER
 #define HVSC_INDEX_DATABASE        @"asma33.sql"
#endif
#ifdef MODPLAYERLITE
 #define HVSC_INDEX_DATABASE        @"modland090406Small.sql"
#endif
#ifdef MODPLAYER
 #define HVSC_INDEX_DATABASE		@"modland120615.sql"
#endif

#ifndef HVSC_INDEX_DATABASE
 #error UNDEFINED HVSC_INDEX_DATABASE
#endif

#define HVSC_CONTENT_DATABASE	@"files.sql"

#import "AppDelegate.h"
#import "SongsByAuthorViewController.h"
#import "PlayerViewController.h"
#import "SearchViewController.h"
#import "DatabaseManager.h"
#import "Playlist.h"
#import "Song.h"
#import "Reachability.h"

#import "KeychainItemWrapper.h"
#define kAppIdentifier @"9H5EKC744L.de.vanille.player"
//#define kAppIdentifier @"AX8H354J9K.de.vanille.player"

#ifdef SIDPLAYER
 #import "PlayerLibSidplay.h"
 #define PLAYER_CLASS PlayerLibSidplay
#endif

#if defined(MODPLAYER) || defined(MODPLAYERLITE)
 #import "PlayerLibModPlug.h"
 #define PLAYER_CLASS PlayerLibModPlug
#endif

#ifdef ATARIPLAYER
 #import "PlayerAsap.h"
 #define PLAYER_CLASS PlayerAsap
#endif

#ifndef PLAYER_CLASS
 #error need to define player class
#endif

#import "AudioQueueDriver.h"

/* SDK */
#import <MediaPlayer/MediaPlayer.h>

// Private interface for Sid_MachineAppDelegate - internal only methods.
@interface Sid_MachineAppDelegate ()

- (void) initAudio;
- (void) initVersioning;
- (void) initCache;
- (void) initMirrors;
- (void) downloadFromServer:(Song*)song;
- (void) getFileByURL:(NSString*)theURL;
- (void) startOrStopDownloadHVSC;
- (void) setDownloadsBadge:(NSInteger)value;
- (void) continueDownloadHVSC;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (void) secondsTimer:(NSTimer*)theTimer;
- (void) positionTimer:(NSTimer*)theTimer;
- (bool) isPlayerVisible;
- (NSInteger) numberOfSongsInDownloadsDirectory;
- (NSString*) filenameForSong:(Song*)song;
- (void) updatePlayerTransport;
- (void) updatePlaybackSettings;

@end

@implementation Sid_MachineAppDelegate

#ifdef SIDPLAYER
PlaybackSettings* playbackSettings;
#endif
PLAYER_CLASS *player;

AudioDriver*	  audioDriver;
NSUInteger		  preloadStartPK;
NSUInteger		  preloadStopPK;
NSUInteger		  preloadCounter;
bool			  alertVisible;

@synthesize dataPath;

@synthesize window;
@synthesize pleaseWaitController;
@synthesize playerController;
@synthesize myTabBarController;
@synthesize downloadAllButton;
@synthesize downloadInProgress;

@synthesize lastKnownSong, currentSong, nextSong;

@synthesize database;
@synthesize filedb;
@synthesize playlist;

@synthesize appName;
@synthesize pkAuthor;
@synthesize authorName;
@synthesize lastSearch;

@synthesize automaticPlayNext;
@synthesize overrideSongLength;
@synthesize offlineMode;
@synthesize defaultSongLength;
@synthesize forceNtscMode;
@synthesize intSidMode;
@synthesize firstStart;
@synthesize enablePerformanceCheck;
@synthesize enableOscillator;
@synthesize pauseWhenLeavingPlayer;
@synthesize restartSearch;
@synthesize applicationRunningInBackground;

@synthesize wrapper;
@synthesize mpNowPlayingInfoCenter;

@synthesize firstStartOfNewVersion;

#pragma mark -
#pragma mark life cycle
#pragma mark

- (void)dealloc
{
	[dataPath release];
	[playlist release];
	[myTabBarController release];
	[playerController release];
	[pleaseWaitController release];
	[appName release];
	[pkAuthor release];
	[authorName release];
	[lastSearch release];

	[window release];
	[currentSong release];
	
	[database release];
	[filedb release];
	
	[wrapper release];

	[super dealloc];
}

- (void) alertView:(UIAlertView *) alertView clickedButtonAtIndex:(int) index
{
	[alertView release];
	if (index == 1)
	{
#ifdef SIDPLAYERPRO
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://itunes.com/apps/sidplayerpro"]];
#endif

#ifdef MODPLAYER
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://itunes.com/apps/modplayer"]];
#endif

#ifdef SIDPLAYER
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://itunes.com/apps/sidplayer"]];
#endif
	}
//	else
//	{
		exit(0);
//	}
}

-(void) alertCrackWithTracking:(BOOL)track
{
#ifdef BUILD_MODE_DEBUG
#else
	if (track)
	{
		NSString* path = [[NSBundle mainBundle] bundlePath];
		NSString* finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
		NSDictionary* plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
		NSString* appIdentifier = [NSString stringWithFormat:@"%@", [plistData objectForKey:@"CFBundleIdentifier"]];
		NSString* appVersion = [NSString stringWithFormat:@"%@", [plistData objectForKey:@"CFBundleVersion"]];
		
		NSString* url = [NSString stringWithFormat:@"http://www.thrust.de/php/track.php?name=%@_%@&uid=%@",appIdentifier, appVersion, [UIDevice currentDevice].uniqueIdentifier];
		NSData* response = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
	}
#endif
	NSLog(@"Application is cracked");
	
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Illegal copy detected"
												 message:[NSString stringWithFormat:@"Your version of %@ is cracked. To support further development and get full access please buy the app in iTunes. Do you want to visit iTunes now?", self.appName]
												delegate:self
									   cancelButtonTitle:@"No way!"
									   otherButtonTitles:@"Ok!", nil];
	[av show];
}	

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	pleaseWaitController = [[PleaseWaitController alloc] initWithNibName:@"PleaseWaitController" bundle:nil];

	[NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(deferredLaunching:) userInfo:nil repeats:NO];
    
    window.rootViewController = pleaseWaitController;
	[window makeKeyAndVisible];	
}

-(void)applicationWillResignActive:(UIApplication *)application
{
	self.applicationRunningInBackground = YES;
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
	self.applicationRunningInBackground = NO;
}

- (void)deferredLaunching:(id)sender
{
	// check for update
	[self initVersioning];
	
	// init database
	NSLog(@"Databasefile:%@", HVSC_INDEX_DATABASE);
	database = [[DatabaseManager alloc] init];
	[database initDatabase:HVSC_INDEX_DATABASE];
	
	// init filemanager
	filedb = [[FileManager alloc] init];
	[filedb initDatabase:HVSC_CONTENT_DATABASE];
    
    if ( firstStartOfNewVersion == YES )
    {
        // will empty cache or each new start now
        [self eraseDownloadCache];
    }

	// init appName
	NSString* path = [[NSBundle mainBundle] bundlePath];
	NSString* finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary* plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];
	NSString* identifier = [NSString stringWithFormat:@"%@", [plistData objectForKey:@"CFBundleIdentifier"]];
	if([identifier compare:@"de.vanille.sidplayer"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Sid Player"];
	else if ([identifier compare:@"de.vanille.sidplayerpro"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Sid Player Pro"];
	else if ([identifier compare:@"de.vanille.modplayer"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Mod Player"];
	else if ([identifier compare:@"de.vanille.modplayerlite"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Mod Player Lite"];
	else if ([identifier compare:@"de.vanille.pokeyplayer"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Pokey Player"];
	else if ([identifier compare:@"de.vanille.pokeyplayerlite"] == NSOrderedSame)
		self.appName = [NSString stringWithString:@"Pokey Player Lite"];
	else
		self.appName = [NSString stringWithString:@"unknown player"];
	[plistData release];

#if not TARGET_IPHONE_SIMULATOR
	if ( YES )
	{
        @try
        {
            self.wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:kAppIdentifier];
            NSString* installed = [wrapper objectForKey:(id)kSecValueData];
            
            if ([installed isEqualToString:@""] || !installed)
            {
                [wrapper setObject:@"LaTe" forKey:(id)kSecAttrAccount];
                [wrapper setObject:@"YES" forKey:(id)kSecValueData];
                NSLog(@"Found no key within keychain - wrote new one!");
            }
            else
            {
                NSLog(@"Found key in KeyChain: %@", installed);
#ifdef LATEDEBUG
                [wrapper resetKeychainItem];
                NSLog(@"Keychain item reset");
#endif
            }
        }
        @catch ( NSException* e )
        {
            NSLog( @"ERROR: %@", e );
        }
	}
#endif

	// initialize on-disk cache
	[self initCache];

	// create URL mirror array
	[self initMirrors];

	// init Playlist
	playlist = [[Playlist alloc] init];
		
	// update display
	[pleaseWaitController.view removeFromSuperview];	
	[window addSubview:myTabBarController.view];
	
	// check whether we have some defaults
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	firstStart = [NSNumber numberWithBool:[prefs boolForKey:@"firstStart"]];
	if ( ![firstStart boolValue] )
	{
		NSLog(@"looks like this is the very first start of Sid Player... initializing defaults");
		// set default values
		[prefs setBool:true						forKey:@"automaticPlayNext"];
		[prefs setBool:false					forKey:@"overrideSongLength"];
		[prefs setBool:false					forKey:@"offlineMode"];
		[prefs setInteger:300					forKey:@"defaultSongLength"];
		[prefs setBool:false					forKey:@"forceNtscMode"];
		[prefs setInteger:0						forKey:@"intSidMode"];

		[prefs setInteger:0						forKey:@"tab"];
		[prefs setObject:nil					forKey:@"currentPlaylist"];
		[prefs setObject:@""					forKey:@"currentAuthor"];
		[prefs setObject:@""					forKey:@"authorName"];
		[prefs setObject:@""					forKey:@"lastSearch"];
		[prefs setBool:false					forKey:@"songslistVisible"];
		[prefs setBool:true						forKey:@"enablePerformanceCheck"];
		[prefs setBool:false					forKey:@"enableOscillator"];
		[prefs setBool:false					forKey:@"pauseWhenLeavingPlayer"];
		
		[prefs setInteger:SIDPLAYER_APP_VERSION	forKey:@"__version__"];
		[prefs setBool:true forKey:@"firstStart"];

		[prefs synchronize];
	}

	// restore preferences and settings
	pkAuthor = [prefs objectForKey:@"currentAuthor"];
	authorName = [prefs objectForKey:@"authorName"];
	lastSearch = [prefs objectForKey:@"lastSearch"];
	BOOL songslistVisible = [prefs boolForKey:@"songslistVisible"];

	enablePerformanceCheck = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"enablePerformanceCheck"]];
	enableOscillator = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"enableOscillator"]];
	pauseWhenLeavingPlayer = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"pauseWhenLeavingPlayer"]]; 
	automaticPlayNext = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"automaticPlayNext"]];
	overrideSongLength = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"overrideSongLength"]];
	offlineMode = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"offlineMode"]];
	defaultSongLength = [[NSNumber alloc] initWithInteger:[prefs integerForKey:@"defaultSongLength"]];
	forceNtscMode = [[NSNumber alloc] initWithBool:[prefs boolForKey:@"forceNtscMode"]];
	intSidMode = [[NSNumber alloc] initWithInteger:[prefs integerForKey:@"intSidMode"]];

	NSArray* loadedPlaylist = [prefs objectForKey:@"currentPlaylist"];
//	[playlist restorePlaylist:loadedPlaylist];
	[loadedPlaylist release];

	int tab = [prefs integerForKey:@"tab"];
	myTabBarController.selectedIndex = tab;
	
	[self notifyOfflineMode];

	if (songslistVisible)
	{
		[self showSongslist:[pkAuthor intValue] withName:authorName ];
	}

	// did we ever count all songs in the database?
	bool songsHaveBeenCounted = [prefs boolForKey:@"songsHaveBeenCounted"];
	if (songsHaveBeenCounted)
	{
		NSNumber* songsInDatabase = [[NSNumber alloc] initWithInteger:[prefs integerForKey:@"songsInDatabase"]];
		filedb.fileCount = songsInDatabase;
		NSLog(@"songs have been counted before: %d", [songsInDatabase integerValue]);
	}
	else
	{
		[filedb countInDatabase];
		[prefs setBool:true										forKey:@"songsHaveBeenCounted"];
		[prefs setInteger:[filedb.fileCount integerValue]		forKey:@"songsInDatabase"];
		[prefs synchronize];
		NSLog(@"songs have never been counted before: %d", [filedb.fileCount integerValue]);
	}
	

#if defined(SIDPLAYER) || defined(ATARIPLAYER) || defined(ATARIPLAYERLITE)
	// check if the whole hvsc is allready downloaded
	if ([database getHighestPK] == [filedb count])
	{
		NSLog(@"HVSC is downloaded allready");
		[downloadAllButton setEnabled:NO];
	}
#else
	[downloadAllButton setEnabled:NO];
#endif
	
	// init audio subsystems
	[self initAudio];
    // reinit window
    [window makeKeyAndVisible];

	// init video out
#ifdef __INCLUDE_TVOUT_SUPPORT
	[MPTVOutWindow createAndMakeKeyWindow];
	[MPTVOutWindow startTvOut:15];  // Set frame rate to 15 FPS
	[window makeKeyAndVisible]; // Not required if window not yet created
#endif
	
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
	NSLog(@"Application launched with handleOpenURL:%@", url);
    // You should be extremely careful when handling URL requests.
    // You must take steps to validate the URL before handling it.
    
    if (!url) {
        // The URL is nil. There's nothing more to do.
        return NO;
    }
    
    NSString *URLString = [[url absoluteString] stringByReplacingOccurrencesOfString:@"sidplayer://" withString:@"http://"];
    if (!URLString) {
        // The URL's absoluteString is nil. There's nothing more to do.
        return NO;
    }
	
	// Your application is defining the new URL type, so you should know the maximum character
    // count of the URL. Anything longer than what you expect is likely to be dangerous.
    NSInteger maximumExpectedLength = 50;
    
    if ([URLString length] > maximumExpectedLength) {
        // The URL is longer than we expect. Stop servicing it.
        return NO;
    }

	NSString* fileName = [[NSString alloc] initWithFormat:@"%s", "external"];
	NSString* destination = [dataPath stringByAppendingPathComponent:fileName];
	[[SongCacheConnection alloc] initWithPath:URLString
								  destination:destination
									 sizeHint:0
									 delegate:self
								   preloading:false
							   externalServer:true];
	[fileName release];
	
	return YES;
}

-(void) showSongslist: (NSInteger) pkToShow withName:(NSString*) showName
{
	self.myTabBarController.selectedIndex = 0;
	
	UINavigationController* navCon = (UINavigationController*)[[myTabBarController viewControllers] objectAtIndex:0];
	
	SongsByAuthorViewController *targetViewController;
	targetViewController = [[SongsByAuthorViewController alloc] initWithNibName:@"SongsByAuthorViewController" bundle:nil];
	targetViewController.pkAuthor = pkToShow;
	
	[targetViewController.navigationItem setTitle:showName];
	
	[navCon pushViewController:targetViewController animated:NO];
	[targetViewController release];
}

#pragma mark -
#pragma mark Private methods
#pragma mark -

-(void) initVersioning
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	unsigned int __version__ = [prefs integerForKey:@"__version__"];
	if ( !__version__ ) // earlier releases were missing this
		__version__ = 2049;
	
	NSLog(@"SidPlayer version %d starting on documents folder generated by %d", SIDPLAYER_APP_VERSION, __version__ );

    self.firstStartOfNewVersion = NO;
	// are we newer?
	if ( SIDPLAYER_APP_VERSION > __version__ )
	{
		[prefs setInteger:SIDPLAYER_APP_VERSION	forKey:@"__version__"];
		[prefs synchronize];
        self.firstStartOfNewVersion = YES;
		NSLog(@"...done!");
	}
}

-(void)initAudio
{
	// create audio stuff
	player = new PLAYER_CLASS();
	audioDriver = new AudioQueueDriver();
	player->setAudioDriver( audioDriver);
	audioDriver->initialize(); // this may spawn another thread
	audioDriver->setVolume(1.0f);
    // NowPlayingInfoCenter iOS 5.0 onwards
    id cls = NSClassFromString(@"MPNowPlayingInfoCenter");
    self.mpNowPlayingInfoCenter = cls ? [cls defaultCenter] : nil;
}

-(void)initCache {
	// turn off the NSSongCache shared cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                            diskCapacity:0
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];

	// create path to cache directory inside the application's Documents directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	self.dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"SongCache"];

	// check for existence of cache directory
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return;
	}

	NSError* err;
	// create a new cache directory
	if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPath
								   withIntermediateDirectories:NO
													attributes:nil
														 error:&err]) {
		[self AlertWithError:err];
		return;
	}
}

//FIXME: move to SongCacheConnection
- (void)initMirrors {
	// create the URL mirrors using the strings stored in mirrors.plist
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mirrors" ofType:@"plist"];
    if (path) {
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:path];
        for (NSString* mirror in array) {
            [SongCacheConnection addMirror:mirror];
        }
        [array release];
    }
	else
	{
		NSLog(@"No mirrors found! Will not be able to download anything.");
	}
}

-(void) AlertWithError:(NSError*)err
{
    NSString *message = [NSString stringWithFormat:@"Error! %@ %@",
						 [err localizedDescription],
						 [err localizedFailureReason]];

	[self AlertWithMessage:message];
}

-(void) AlertWithMessage:(NSString*)message
{
	
	
	/* open an alert with an OK button */
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.appName
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
	[alert show];
	[alert release];
}

-(void) AlertWithMessageAndDelegate:(NSString*)message WithDelegate:(id)delegate
{
	/* open an alert with OK and Cancel buttons */
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.appName
													message:message
												   delegate:delegate
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles: @"OK", nil];
	[alert show];
	[alert release];
}

# pragma mark -
# pragma mark UIApplication Delegate protocol
# pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self applicationWillTerminate:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// save settings
	NSLog(@"active tab index = %d", myTabBarController.selectedIndex);

	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSInteger selectedIndex =  [myTabBarController selectedIndex];

	BOOL songslisVisible = NO;
	NSArray* ViewControllers = [myTabBarController viewControllers];
	UINavigationController* navCon = (UINavigationController*) [ViewControllers objectAtIndex:0];
	if ([[navCon visibleViewController] isMemberOfClass: [SongsByAuthorViewController class]])
	{
		NSLog(@"Songslist from Author mith pk %@ was visible", pkAuthor);
		songslisVisible = YES;
	}
	
	[prefs setObject:pkAuthor							forKey:@"currentAuthor"];
	[prefs setObject:authorName							forKey:@"authorName"];
	[prefs setObject:lastSearch							forKey:@"lastSearch"];
	[prefs setBool:songslisVisible						forKey:@"songslistVisible"];
	[prefs setBool:[enablePerformanceCheck boolValue]	forKey:@"enablePerformanceCheck"];
	[prefs setBool:[enableOscillator boolValue]			forKey:@"enableOscillator"];
	[prefs setBool:[pauseWhenLeavingPlayer boolValue]	forKey:@"pauseWhenLeavingPlayer"];	
	[prefs setInteger:selectedIndex						forKey:@"tab"];
	[prefs setBool:[automaticPlayNext boolValue]		forKey:@"automaticPlayNext"];
	[prefs setBool:[overrideSongLength boolValue]		forKey:@"overrideSongLength"];
	[prefs setBool:[offlineMode boolValue]				forKey:@"offlineMode"];
	[prefs setInteger:[defaultSongLength intValue]		forKey:@"defaultSongLength"];
	[prefs setBool:[forceNtscMode boolValue]			forKey:@"forceNtscMode"];
	[prefs setInteger:[intSidMode intValue]				forKey:@"intSidMode"];
	[prefs setInteger:[filedb.fileCount integerValue]	forKey:@"songsInDatabase"];

	/*
	if ( currentSong )
		// hier ist ein Crash!!
		[prefs setInteger:currentSong.primaryKey forKey:@"currentSongPK"];
	else
		[prefs setInteger:0					forKey:@"currentSongPK"];
	 */

	NSArray* myPlaylist = [playlist playlistPrimaryKeys];
	[prefs setObject:myPlaylist				forKey:@"currentPlaylist"];
	
	[prefs setBool:[self isPlayerVisible]	forKey:@"playerVisible"];

 	[prefs synchronize];

	[database closeDatabase];
	[filedb closeDatabase];
	
	// See if TV Out should be switched off (only valid in debug mode)
#ifdef __INCLUDE_TVOUT_SUPPORT
	[MPTVOutWindow stopTvOut];
#endif
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	// memory gets low
	NSLog(@"WARNING: Memory got low, trying to recover...");
	if ( downloadInProgress )
		[self startOrStopDownloadHVSC];
	[self doPlayerAction:@"pause"];
	[database closeDatabase];
	[filedb closeDatabase];
}

# pragma mark -
# pragma mark IBAction Methods
# pragma mark -

-(IBAction)downloadHVSC
{
	if ([[Reachability sharedReachability] internetConnectionStatus] != ReachableViaWiFiNetwork)
	{
	// no wifi connection found
		NSString *message = NSLocalizedString(@"download hvsc no wifi", @"");
		[self AlertWithMessage:message];
	}
	else
	{
		// prober connection is available
		if (downloadInProgress == YES)
		{
			DownloadHvscDelegateStart* delegate = [[DownloadHvscDelegateStart alloc] init];
			UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"download hvsc stop", @"")
															   delegate:delegate
													  cancelButtonTitle:NSLocalizedString(@"download hvsc no", @"")
												 destructiveButtonTitle:NSLocalizedString(@"download hvsc stop yes", @"")
													  otherButtonTitles:nil];
			sheet.actionSheetStyle = UIActionSheetStyleDefault;
			[sheet showInView:myTabBarController.selectedViewController.view.window];
			[sheet release];
		}
		else
		{
			DownloadHvscDelegateStart* delegate = [[DownloadHvscDelegateStart alloc] init];
			UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"download hvsc start", @"")
															   delegate:delegate
													  cancelButtonTitle:NSLocalizedString(@"download hvsc no", @"")
												 destructiveButtonTitle:NSLocalizedString(@"download hvsc start yes", @"")
													  otherButtonTitles:nil];
			sheet.actionSheetStyle = UIActionSheetStyleDefault;
			[sheet showInView:myTabBarController.selectedViewController.view.window];
			[sheet release];
		}		
	}
}

-(IBAction)showPlayerWithSong:(id)sender WithSong:(Song*)song
{
	[self showPlayerWithSong:sender	WithSong:song pushPlayer:YES];
}

-(IBAction)showPlayer:(id)sender
{
	if (!playerController)
	{
		NSLog(@"creating playerController for the first time");
		playerController = [[PlayerViewController alloc] initWithNibName:@"PlayerWindow" bundle:nil];
		[playerController navigationItem].title = NSLocalizedString(@"Now Playing", @"");
	}
	UINavigationController* activeNavigationController = (UINavigationController*) [myTabBarController selectedViewController];
	
	/* push playerController only if it's not already seen */
	
	if ( [[activeNavigationController topViewController] class] != [PlayerViewController class])
	{
		NSLog(@"launching playerController");
		playerController.hidesBottomBarWhenPushed = YES;
		[[activeNavigationController navigationBar] setBarStyle:UIBarStyleBlackOpaque];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
													animated:YES ];
		[activeNavigationController pushViewController:playerController
											  animated:YES];
	}
	else
	{
		NSLog(@"PlayerViewController is topViewController already, I better don't push it.");
	}
}

# pragma mark -
# pragma mark Public Methods
# pragma mark -

-(void)showPlayerWithSong:(id)sender WithSong:(Song*)song pushPlayer:(BOOL)push
{
	NSLog(@"showPlayerWithSong: %@", song.name);

	if (currentSong) {
		[self doPlayerAction:@"pause"];
	}

	[nextSong release];
	[song retain];
	nextSong = song;
	if (push)
		// show first, so we get something going on the UI
		[self showPlayer:self];

	if ( [filedb isFilesInDb:nextSong.primaryKey] )
	{
		NSLog(@"Playing song from cache.");
		NSData* songBuffer = [filedb openFile:nextSong.primaryKey];
		[self playBufferedSong: songBuffer];
	}
	else
	{
		NSLog(@"Loading song into cache...");
		[self getFileByURL:nextSong.uri];
	}
}

- (bool) isPlayerVisible
{
	// if no UINavigationController...
	UIViewController* selectedController = [myTabBarController selectedViewController];
	if ([selectedController superclass] == [UITableViewController class]) {
		return NO;
	} else {
		//	UINavigationController* activeNavigationController = (UINavigationController*) [myTabBarController selectedViewController];
		return [[(UINavigationController*) selectedController topViewController] class] == [PlayerViewController class];
	}

}

- (void) setDownloadsBadge:(NSInteger)value
{
	value--;
	NSArray* tabs = [myTabBarController viewControllers];
	if (value > 0)
	{
		NSString* valueString = [[NSString alloc] initWithFormat:@"%d", value];
		[[tabs objectAtIndex:0] tabBarItem].badgeValue = valueString;
		[valueString release];
	}
	else
		[[tabs objectAtIndex:0] tabBarItem].badgeValue = nil;
}

- (void) notifyOfflineMode
{
	NSArray* tabs = [myTabBarController viewControllers];
	if ( [self.offlineMode boolValue])
	[[tabs objectAtIndex:3] tabBarItem].badgeValue = @"Offline";
	else
		[[tabs objectAtIndex:3] tabBarItem].badgeValue = nil;
	// set some notifications
	database.rebuildCache = YES;
	database.authorsHaveChanged = YES;
}

- (void) startOrStopDownloadHVSC
{
	if (downloadInProgress == YES)
	{
		NSLog(@"Stop downloading HVSC now!");
		preloadCounter = 0;
		[self setDownloadInProgress: NO];
		[downloadAllButton setImage: [UIImage imageNamed:@"DownloadAll.png"]];
		// check if the whole hvsc is allready downloaded
		if ([database getFirstUncachedPK] == 0)
		{
			NSLog(@"HVSC is downloaded allready");
			[downloadAllButton setEnabled:NO];
		}
	}
	else
	{
		NSLog(@"Starting to preload the whole HVSC Collection...");
		preloadStopPK = [database getHighestPK];
		preloadCounter = preloadStopPK - [filedb count];
		preloadStartPK = [database getFirstUncachedPK];		// OK
		if ( preloadCounter > 0 && preloadStartPK != 0 )
		{
			[self setDownloadInProgress: YES];
			[self continueDownloadHVSC];
			[downloadAllButton setImage: [UIImage imageNamed:@"DownloadAllStop.png"]];
			
		}
		else
		{
			[self setDownloadInProgress: NO];
			[downloadAllButton setImage: [UIImage imageNamed:@"DownloadAll.png"]];
			// disable downloadAll Button
			[downloadAllButton setEnabled:NO];
			[filedb setFileCount:[NSNumber numberWithInt:[database getHighestPK]]];
			NSLog(@"HVSC Collection already downloaded.");
		}
	}
}

- (void) continueDownloadHVSC
{
	NSLog(@"AppDelegate: launching HVSC preload for song with primary key %d", preloadStartPK);
	[self setDownloadsBadge:preloadCounter];
	if (preloadCounter > 0)
	{
		preloadCounter--;
		
		NSString* fileName = [[NSString alloc] initWithFormat:@"%d", preloadStartPK];
		NSString* destination = [dataPath stringByAppendingPathComponent:fileName];
		Song* song = [database getSongByPK:preloadStartPK];
		[[SongCacheConnection alloc] initWithPath:song.uri
									  destination:destination
										 sizeHint:0 // SIDs have no size hint
										 delegate:self
									   preloading:true
								   externalServer:false];
		[fileName release];
		[song release];
	}
}

- (void) getFileByURL:(NSString*)theURL {
	[playerController startAnimation];
	NSString* fileName = [[NSString alloc] initWithFormat:@"%d", nextSong.primaryKey];
	NSString* destination = [dataPath stringByAppendingPathComponent:fileName];
#if SIDPLAYER
	(void) [[SongCacheConnection alloc] initWithPath:theURL
										 destination:destination
											sizeHint:0 // SIDs have no size hint
											delegate:self
										  preloading:false
									  externalServer:false];
#else
	(void) [[SongCacheConnection alloc] initWithPath:theURL
										 destination:destination
											sizeHint:nextSong.duration
											delegate:self
										  preloading:false
									  externalServer:false];
#endif
	[fileName release];
}

- (void) eraseDownloadCache
{
	NSLog(@"Erasing download cache in %@...", dataPath );
    if ( audioDriver )
    {
        audioDriver->stopPlayback();
    }

	/*
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:dataPath error:NULL];
	*/
	[database removeCachedEntries];

	[filedb deleteAllFiles];
	[playlist deletePlaylist];
	[playerController reset];
	[self initCache];
	[downloadAllButton setEnabled:YES];
}

- (void) erasePlayedSongs
{
	NSLog(@"Erasing played songs");
	audioDriver->stopPlayback();

	[database removePlayedEntries];
	[playlist deletePlaylist];
	if (playerController)
		[playerController reset];
}

- (void) eraseSongFile: (Song *)delSong
{
	NSString* songPath = [[NSString alloc] init];
	NSString* fileName = [[NSString alloc] initWithFormat:@"%i", [delSong primaryKey]];
	songPath = [[dataPath stringByAppendingPathComponent:fileName] retain];
	[fileName release];
	
	NSLog(@"Erasing song from cache: %@", songPath);
	if ([delSong primaryKey] == [currentSong primaryKey])
	{
		// is that correct? shouldn't we rather call doPlayerAction:@"pause"?
		audioDriver->stopPlayback();
	}
	// delete file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:songPath error:NULL];
	[songPath release];
	// update datebase
	[database removeSongCount: [delSong primaryKey]];
}


#pragma mark -
#pragma mark CacheConnectionDelegate methods
#pragma mark -

- (void) connectionProgress:(SongCacheConnection*)theConnection
				haveAlready:(NSUInteger)already
					ofTotal:(NSUInteger)total
{
	NSLog(@"updating download progress %d of %d", already, total);
	[playerController updateAnimation:already ofTotal:total];
}

- (void) connectionDidFail:(SongCacheConnection *)theConnection {
	NSLog(@"connectionDidFail");
	
	if (theConnection.preloading)
	{
		NSLog(@"stopping preloading the HVSC");
		// FIXME: show alert if connection failed!
		[self setDownloadsBadge:0];
	}
	else
	{
		[playerController stopAnimation];
		[self AlertWithMessage:NSLocalizedString(@"File not found", @"")];
		[theConnection release];
	}
}

- (void) connectionDidFinish:(SongCacheConnection *)theConnection
{
	NSLog(@"AppDelegate: Connection did finish. File path: %@ now valid.", theConnection.destinationPath);
	
	if ( theConnection.preloading )
	{
		NSLog(@"    this connection is part of preloadeding from HVSC. Continuing to next song.");
		[database markSongAsCached:preloadStartPK];

		// upload to database
		[filedb saveFile:preloadStartPK];

		// add cache count
		Song* newSong = [database getSongByPK:preloadStartPK];
		[database incrementSongCacheCount: newSong];
		[newSong release];

		// file will no longer be used
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:theConnection.destinationPath error:NULL];

		// check next one
		preloadStartPK = [database getFirstUncachedPK];
		if ( preloadStartPK == 0 )
		{
			NSLog(@"    HVSC has been completely downloaded. Congratulations.");
			[self startOrStopDownloadHVSC];
		}
		else
		{
			[self continueDownloadHVSC];
		}
	}
	else
	{
		[nextSong setCached:YES];

		[database markSongAsCached:nextSong.primaryKey];
		[playerController stopAnimation];

		// upload to database
		[filedb saveFile:nextSong.primaryKey];
		
		// add cache count
		[database incrementSongCacheCount: nextSong];
		
		NSLog(@"Playing song from cache.");
		NSData* songBuffer = [filedb openFile:nextSong.primaryKey];
		[self playBufferedSong: songBuffer];
		
		// file will no longer be used
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:theConnection.destinationPath error:NULL];

	}
	[theConnection release];
}

#pragma mark -
#pragma mark Player Engine Actions
#pragma mark -

-(void) remoteControlReceivedWithEvent:(UIEvent *)event
{
	NSLog(@"remoteControlReceivedWithEvent: %d", event.subtype);
	switch (event.subtype)
	{
		case UIEventSubtypeRemoteControlTogglePlayPause:
			[self doPlayerAction: ( audioDriver->getIsPlaying() ) ? @"pause" : @"play"];
			break;
		case UIEventSubtypeRemoteControlPlay:
			[self doPlayerAction:@"play"];
			break;
		case UIEventSubtypeRemoteControlPause:
			[self doPlayerAction:@"pause"];
			break;
		case UIEventSubtypeRemoteControlStop:
			[self doPlayerAction:@"pause"];
			break;
		case UIEventSubtypeRemoteControlNextTrack:
			[playerController playNextSong:self];
			break;
		case UIEventSubtypeRemoteControlPreviousTrack:
			[playerController playPrevSong:self];
			break;
		default:
			break;
	}
}

-(void) doPlayerAction:(NSString*)action
{
	if ( action == @"ns" )
	{
		player->startNextSubtune();
		[self updatePlayerWindow];
	}
	else if ( action == @"ps" )
	{
		player->startPrevSubtune();
		[self updatePlayerWindow];
	}
	else if ( action == @"pause" )
	{
		audioDriver->stopPlayback();
		[self updatePlayerTransport];
	}
	else if ( action == @"play" )
	{
		audioDriver->startPlayback( player );
		[self updatePlayerTransport];
	}
	else if ( action == @"r" )
	{
		[self restartCurrentSong];
	}
	else if ( action == @"p" )
	{
		Song* prevSong = [playlist previousSong];
		if (prevSong != nil)
			[self showPlayerWithSong:self WithSong:prevSong];
		else
			NSLog(@"No Song found in Playlist....");
	}
	else if ( action == @"n" )
	{
		Song* nextSong2 = [playlist nextSong];
		if (nextSong2 != nil)
			[self showPlayerWithSong:self WithSong:nextSong2];
		else
			NSLog(@"No Song found in Playlist....");
	}
	else if ( action == @"nnw" )
	{
		Song* nextSong2 = [playlist nextSong];
		if (nextSong2 != nil)
			[self showPlayerWithSong:self WithSong:nextSong2 pushPlayer:NO];
		else
			NSLog(@"No Song found in Playlist....");
	}

	else
		assert( false ); // fail here if unknown action has been requested
}

-(void) seek:(double)to
{
	player->seek( to );
}

-(void) updatePlayerWindow
{
	NSLog(@"updating player window from app delegate");
	if (playerController )
	{
		NSString* theTitle = [[NSString alloc] initWithCString:player->getCurrentTitle() encoding:NSWindowsCP1252StringEncoding];
		unsigned int theSubtune = player->getCurrentSubtune();
		unsigned int maxSubtune = player->getSubtuneCount();
        
#ifdef SIDPLAYER
		NSString* theAuthor = [[NSString alloc] initWithCString:player->getAuthor() encoding:NSWindowsCP1252StringEncoding];
		NSString* thePublisher = [[NSString alloc] initWithCString:player->getReleaseInfo() encoding:NSWindowsCP1252StringEncoding];
		NSString* theInfo = [[NSString alloc] initWithString:[database getSongInformationsByPK:[currentSong primaryKey]]];
#endif
		
#if defined(MODPLAYER) || defined(MODPLAYERLITE)
		NSString* theAuthor;
		if (currentSong.authorName != nil)
			theAuthor = [[NSString alloc] initWithString:currentSong.authorName];
		else
			theAuthor = @"(?)";
		NSString* thePublisher = [[NSString alloc] initWithCString:player->getReleaseInfo() encoding:NSWindowsCP1252StringEncoding];
		NSMutableString* theInfo = [[NSMutableString alloc] initWithString:@""];
		[theInfo appendString:@"---------------------------\n"];
		[theInfo appendFormat:@"Number of patterns: %d\n", player->getNumberOfPatterns()];
		[theInfo appendFormat:@"Number of channels: %d\n", player->getNumberOfChannels()];
		[theInfo appendFormat:@"Number of samples: %d\n", player->getNumberOfSamples()];
		[theInfo appendString:@"-------------------------\n"];
		[theInfo appendString:@"      S A M P L E S      \n"];
		[theInfo appendString:@"-------------------------\n"];
		for ( int i = 0; i < player->getNumberOfSamples(); ++i )
		{
			[theInfo appendFormat:@"%s\n", player->getSampleName(i)];
		}
		[theInfo appendString:@"-------------------------\n"];
#endif

#ifdef ATARIPLAYER
		NSString* theAuthor = [[NSString alloc] initWithCString:player->getAuthor() encoding:NSWindowsCP1252StringEncoding];
		NSString* thePublisher = [[NSString alloc] initWithCString:player->getReleaseInfo() encoding:NSWindowsCP1252StringEncoding];
		NSString* theInfo = [[NSString alloc] initWithString:[database getSongInformationsByPK:[currentSong primaryKey]]];
#endif		
		
        if ( self.mpNowPlayingInfoCenter )
        {
            NSString* titleInfo = [NSString stringWithFormat:@"%@ – %@", theAuthor, theTitle];
            NSDictionary* info = [[NSDictionary alloc] initWithObjectsAndKeys:titleInfo, MPMediaItemPropertyTitle, theAuthor, MPMediaItemPropertyArtist, nil]; 
            [self.mpNowPlayingInfoCenter setNowPlayingInfo:info];
        }
		[playerController updateSongInfo: theTitle
							 WithSubtune: theSubtune
						  WithMaxSubtune: maxSubtune
							  WithAuthor: theAuthor
						   WithPublisher: thePublisher
						   WithStilEntry: theInfo
						WithHavePrevSong: ( [playlist previousSong] != nil )
						WithHaveNextSong: ( [playlist nextSong] != nil )
						  WithIsFavorite: [database isFavorite:[currentSong primaryKey]]];
		[theTitle release];
		[theAuthor release];
		[thePublisher release];
		[theInfo release];
	}
}

-(void) updatePlayerTransport
{
	[playerController updateTransportButtons:audioDriver->getIsPlaying()];
}

-(void) restartCurrentSong
{
	if ( !currentSong || !audioDriver->getIsPlaying() )
	{
		return;
	}
	else
	{
		[self showPlayerWithSong:self WithSong:currentSong pushPlayer:false];
	}
}

/*************************************************************
 * SID PLAYER
 *************************************************************/
#ifdef SIDPLAYER
-(void) updatePlaybackSettings
{
	// Modify at your will here...
	NSLog(@"setting playback clock speed to %s", [forceNtscMode boolValue]? "NTSC": "PAL" );
	playbackSettings->mClockSpeed = [forceNtscMode boolValue]? 1:0; // 0=PAL; 1=NTSC
	
	int sidMode = [intSidMode intValue];
	
	NSLog(@"setting playback sid model to %d", sidMode );
	
	switch ( sidMode )
	{
		case 0:
			playbackSettings->mForceSidModel = false;
			playbackSettings->mSidModel = 0;
			playbackSettings->mFilterType = SID_FILTER_6581_Resid;
			break;
		case 1:
			playbackSettings->mForceSidModel = true;
			playbackSettings->mSidModel = 0;
			playbackSettings->mFilterType = SID_FILTER_6581_Resid;
			break;
		case 2:
			playbackSettings->mForceSidModel = true;
			playbackSettings->mSidModel = 0;
			playbackSettings->mFilterType = SID_FILTER_6581R3;
			break;
		case 3:
			playbackSettings->mForceSidModel = true;
			playbackSettings->mSidModel = 0;
			playbackSettings->mFilterType = SID_FILTER_6581R4;
			break;
		case 4:
			playbackSettings->mForceSidModel = true;
			playbackSettings->mSidModel = 0;
			playbackSettings->mFilterType = SID_FILTER_6581_Galway;
			break;
		case 5:
			playbackSettings->mForceSidModel = true;
			playbackSettings->mSidModel = 1;
			playbackSettings->mFilterType = SID_FILTER_8580;
			break;
		default:
			assert(false); // should never reach this
	}
	
}

-(void) playBufferedSong:(NSData*)buffer
{
	if (currentSong)
		lastKnownSong = currentSong;
	currentSong = nextSong;
	nextSong = null;	
	
	NSLog(@"AppDelegate: playBufferedSong");
	if ( playbackSettings )
		delete playbackSettings;
	
	playbackSettings = new PlaybackSettings();
	memset( playbackSettings, 0, sizeof (PlaybackSettings) );
	
	// These three are not modifiable
	playbackSettings->mFrequency = 44100;
	playbackSettings->mBits = 16;
	playbackSettings->mStereo = true;
	
	// This should be left as is
	playbackSettings->mOptimization = 2;
	playbackSettings->mOversampling = 1;
	playbackSettings->mFilterKinkiness = 0.17f;
	playbackSettings->mFilterBaseLevel = 210.0f;
	playbackSettings->mFilterOffset = -375.0f;
	playbackSettings->mFilterSteepness = 120.0f;
	playbackSettings->mFilterRolloff = 5.5f;
	playbackSettings->mDistortionRate = 1500;
	playbackSettings->mDistortionHeadroom = 400;
	
	[self updatePlaybackSettings];

	char* myBuffer = (char*) [buffer bytes];
	bool success = player->playTuneFromBuffer( myBuffer, [buffer length], 0, playbackSettings);
	[buffer release];
	fprintf(stderr, "success=%d\n", success);
	
	if ( success == 1 )
	{
		[database addSongCount:currentSong.primaryKey];
		[self updatePlayerWindow];
	}
	else
	{
		NSLog(@"could not play file :(");
		[self doPlayerAction:@"pause"];
		[self AlertWithMessage:NSLocalizedString(@"Playback not possible", @"")];
	}
}
-(void) setVolume:(float)volume forVoice:(NSUInteger)voice
{
	player->setVoiceVolume(voice, volume);
}
#endif

/*************************************************************
 * MOD PLAYER
 *************************************************************/
#if defined(MODPLAYER) || defined(MODPLAYERLITE)
-(void) updatePlaybackSettings
{
	// Modify at your will here...
}

-(void) playBufferedSong:(NSData*)buffer
{
	if (currentSong)
		lastKnownSong = currentSong;
	currentSong = nextSong;
	nextSong = null;	

	NSLog(@"AppDelegate: playBufferedSong");
	[self updatePlaybackSettings];
	
	char* myBuffer = (char*) [buffer bytes];
	bool success = player->playTuneFromBuffer( myBuffer, [buffer length] );
	[buffer release];
	fprintf(stderr, "success=%d\n", success);
	
	if ( success == 1 )
	{
		[database addSongCount:currentSong.primaryKey];
		[self updatePlayerWindow];
	}
	else
	{
		NSLog(@"could not play file :(");
		[self doPlayerAction:@"pause"];
		[self AlertWithMessage:NSLocalizedString(@"Playback not possible", @"")];
	}
}

-(void) setVolume:(float)volume forVoice:(NSUInteger)voice
{
#if 0
	mSettings.mReverbDepth = 60;    /* Reverb level 0(quiet)-100(loud)      */
	mSettings.mReverbDelay = 100;    /* Reverb delay in ms, usually 40-200ms */
	mSettings.mBassAmount  = 30;     /* XBass level 0(quiet)-100(loud)       */
	mSettings.mBassRange   = 70;      /* XBass cutoff in Hz 10-100            */
	mSettings.mSurroundDepth = 100;  /* Surround level 0(quiet)-100(heavy)   */
	mSettings.mSurroundDelay = 40;  /* Surround delay in ms, usually 5-40ms */
	mSettings.mLoopCount = 0;      /* Number of times to loop.  Zero prevents looping. -1 loops forever. */
#endif

	switch (voice)
	{
		case 0: /* Reverb */
			player->setReverb( volume > 0.0f, 100*volume, volume*400 );
			break;
		case 1: /* Surround */
			player->setSurround( volume > 0.0f, volume*100, 80 );
			break;
		case 2: /* Bass */
			player->setBass( volume > 0.0f, volume*100, 70 );
			break;
	}
	player->syncSettings();
}
#endif

/*************************************************************
 * ATARI PLAYER
 *************************************************************/
#ifdef ATARIPLAYER
-(void) updatePlaybackSettings
{
	// NOT YET IMPLEMENTED
}

-(void) playBufferedSong:(NSData*)buffer
{
	if (currentSong)
		lastKnownSong = currentSong;
	currentSong = nextSong;
	nextSong = null;	
	
	NSLog(@"AppDelegate: playBufferedSong");
	
	char* myBuffer = (char*) [buffer bytes];
	bool success = player->playTuneFromBuffer( myBuffer, [buffer length] );
	[buffer release];
	fprintf(stderr, "success=%d\n", success);
	
	if ( success == 1 )
	{
		[database addSongCount:currentSong.primaryKey];
		[self updatePlayerWindow];
	}
	else
	{
		NSLog(@"could not play file :(");
		[self doPlayerAction:@"pause"];
		[self AlertWithMessage:NSLocalizedString(@"Playback not possible", @"")];
	}
}
-(void) setVolume:(float)volume forVoice:(NSUInteger)voice
{
	// NOT IMPLEMENTED YET
}
#endif



-(short*) getSampleBuffer
{
	if ( audioDriver && audioDriver->getIsPlaying() )
	{
		return audioDriver->getSampleBuffer();
	}
	
	return NULL;
}

// called by NSTimer
- (void) secondsTimer
{
	// NSLog(@"timer fired from CFRunLoop %d", CFRunLoopGetCurrent());
	if ( playerController && audioDriver->getIsPlaying() )
	{
#ifdef SIDPLAYER
		int songLength = [overrideSongLength boolValue]? [defaultSongLength intValue]: currentSong.duration;
#else
		int songLength = [overrideSongLength boolValue]? [defaultSongLength intValue]: player->getPlaybackLength();
#endif
		// song duration from database is only valid for default subtune
		if ( player->getCurrentSubtune() == player->getDefaultSubtune() )
			[playerController updateDuration:player->getPlaybackSeconds() WithMaxDuration:songLength];
		else
			[playerController updateDuration:player->getPlaybackSeconds() WithMaxDuration:[defaultSongLength intValue]];
	}

	float driverPerformance = audioDriver->getPerformance();

	if ( [self.enablePerformanceCheck boolValue] && [self isPlayerVisible] )
	{
		if ( driverPerformance > DRIVER_PERFORMANCE_THRESHOLD )
		{
			audioDriver->resetPerformance();
			[self doPlayerAction:@"pause"];
			[database markSongForCeck: currentSong.primaryKey];
			[self AlertWithMessage:NSLocalizedString(@"Song too complex", @"")];
		}
	}
	else
	{
		if ( driverPerformance > DRIVER_PERFORMANCE_THRESHOLD )
			NSLog(@"audio stuttering, but player not visible -- hopefully we're searching or scrolling. Ignoring.");
	}
}

// called by NSTimer
- (void) positionTimer
{
#if defined(MODPLAYER) || defined(MODPLAYERLITE)
	if ( playerController && audioDriver->getIsPlaying() )
	{
		int pattern;
		int row;
		player->getPlaybackPosition( &pattern, &row );
		playerController.position.text = [NSString stringWithFormat:@"P:%02d R:%02d", pattern, row];
	}
#endif
}	

- (void) updatePlaylist:(id)sender
{
	// check who called the update
/*	if ([sender isMemberOfClass: [SongslistViewController class]])
	{
		[playlist setPlaylist:[database songsArray]];
	}
	else */if ([sender isMemberOfClass: [SearchViewController class]])
	{
		[playlist setPlaylist:[database searchSongsArray]];
	}
	else
	{
		NSLog(@"unknown sender trys to set playlist!");
		[playlist setPlaylist:[sender songsArray]];
	}
}

- (NSString*) filenameForSong:(Song*)song
{
	assert( song );
	NSLog(@"AppDelegate: filenameForSong '%@' (pk=%d)?", song.name, song.primaryKey);
	NSString* fileName = [[NSString alloc] initWithFormat:@"%d", song.primaryKey];
	NSString* songPathInCache = [[dataPath stringByAppendingPathComponent:fileName] retain];
	[fileName release];
	[songPathInCache release];
	return songPathInCache;
}
@end

# pragma mark -
# pragma mark DownloadHvscDelegates
# pragma mark -

@implementation DownloadHvscDelegateStart

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	NSLog(@"action on sheet");
	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if ( buttonIndex == 0 )
		[app startOrStopDownloadHVSC];
	
	[self release];

}

@end

@implementation DownloadHvscDelegateStop

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	NSLog(@"action on sheet");
	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if ( buttonIndex == 0 )
		[app startOrStopDownloadHVSC];
	
	[self release];
	
}

@end
