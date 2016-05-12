//
//  SourceTop50.h
//  ModPlayer
//
//  Created by Kai Teuber on 05.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FixedOrderViewController.h"


@interface SourceTop50 : NSObject <PlaylistDataDelegate>
{

	Sid_MachineAppDelegate*		app;
	NSMutableArray*		songPksInPlaylist;
	BOOL				refreshNeeded;
	
}

@property	(nonatomic) BOOL	refreshNeeded;

@end
