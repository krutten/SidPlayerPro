
#import "Top100.h"

@implementation Top100

- (NSMutableArray*) getSongs
{
	songsArray = [[app database] getTop100Songs];
	NSLog(@"%i gespiele Songs gefunden!", [songsArray count]);
	return songsArray;
}

- (BOOL) rebuildViewNeeded
{
	BOOL refresh =  [[app database] rebuildTop100list];
	[[app database] setRebuildTop100list:NO];
	return refresh;
}

@end
