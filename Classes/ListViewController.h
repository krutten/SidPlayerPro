//
//  ListViewController.h
//  ModPlayer
//
//  Created by Kai Teuber on 18.01.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface ListViewController : UITableViewController <CellNotificationDelegate> {

	Sid_MachineAppDelegate* app;

	NSMutableArray* metaData;
	NSMutableArray* realData;

	NSInteger	setCount;
	NSInteger	startId;
	NSInteger	endId;
	NSMutableArray*	names;
	
    NSMutableArray* realPrefixes;
}

@property (nonatomic, retain) NSIndexPath*  indexPathSelected;
@property (nonatomic, assign) NSInteger     indexPathOffset;

// internal
- (void) initModel;

// override for different behavior
- (NSArray*) getCountedArray;
- (int) getDbIndex: (NSIndexPath *) indexPath;
- (int) getDbIndex: (NSIndexPath *) indexPath skipOffest:(NSInteger) offset;
- (void) setNamesFromIndex: (NSInteger) start;

- (void) newSong: (NSInteger) offset;
- (void) startPlayback;
- (void) trackPlayer:(NSIndexPath*) indexPath;
@end
