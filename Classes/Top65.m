
#import "Top65.h"

@implementation Top65

- (NSMutableArray*) getSongs
{
	songsArray = [[app database] getTop65Songs];
	NSLog(@"%i gespiele Songs gefunden!", [songsArray count]);
	return songsArray;
}

- (BOOL) rebuildViewNeeded
{
	BOOL refresh =  [[app database] rebuildTop65list];
	[[app database] setRebuildTop65list:NO];
	return refresh;
}

@end
