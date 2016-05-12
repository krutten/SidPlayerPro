//
//  FixedOrderViewController.h
//  ModPlayer
//
//  Created by Kai Teuber on 03.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListViewController.h"

@protocol PlaylistDataDelegate;

@interface FixedOrderViewController : ListViewController {
	
	id <PlaylistDataDelegate> delegate;
	NSInteger	numberOfCommands;

@protected
	CFAbsoluteTime				lastTapTime;
	NSIndexPath*				lastIndexPath;
@protected
	NSUInteger					lastTapRow;
@protected
	BOOL						ignoreSelector;
}

@property (nonatomic, retain) id <PlaylistDataDelegate> delegate;
@property (nonatomic) BOOL						ignoreSelector;
@property (nonatomic, retain)   NSIndexPath*    lastIndexPath;

-(void) showSongsByAuthor: (Song*) newSong;

@end

// declare a needed protocol
@protocol PlaylistDataDelegate

- (NSArray*) getSongNames:(NSInteger) start limitBy:(NSInteger) limit;
- (NSInteger) countedSongs;
- (void) deleteSong: (NSInteger) songPK;
- (BOOL) refreshNeeded;
- (void) setRefreshNeeded: (BOOL)value;
- (NSArray*) getPlaylistPKs;

@optional
- (void) shufflePlaylist;
- (BOOL) moveSongFromIndex:(NSInteger) from toIndex:(NSInteger) to;

@end
