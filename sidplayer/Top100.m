
#import "Top100.h"

@implementation Top100

#define TOP100_COUNT 93

int hvscTop100pk[] = {\
					  10820,
					  14367,
					  16073,
					  16049,
					  16029,
					  31091,
					  16034,
					  14357,
					  16059,
					  14333,
					  16032,
					  31090,
					  24444,
					  14936,
					  14891,
					  16053,
					  16020,
					  9184,
					  16060,
					  14338,
					  7636,
					  12654,
					  10790,
					  16112,
					  31133,
					  13900,
					  6113,
					  14355,
					  16056,
					  11641,
					  14336,
					  14368,
					  17747,
					  31166,
					  16057,
					  16078,
					  10848,
					  6117,
					  16108,
					  16048,
					  10847,
					  14231,
					  16092,
					  31158,
					  14919,
					  16064,
					  31149,
					  16017,
					  16084,
					  14879,
					  16021,
					  34689,
					  16136,
					  2252,
					  33008,
					  13899,
					  15626,
					  6103,
					  13910,
					  5799,
					  14249,
					  16058,
					  16120,
					  16042,
					  2654,
					  31100,
					  10786,
					  9194,
					  10772,
					  16090,
					  10849,
					  14366,
					  16824,
					  14351,
					  9492,
					  31083,
					  16846,
					  31089,
					  31109,
					  14360,
					  18929,
					  33703,
					  31123,
					  32405,
					  6119,
					  16050,
					  6075,
					  8557,
					  31077,
					  4924,
					  14352,
					  33022,
					  7622 };

- (NSMutableArray*) getSongs
{
	songsArray = [[app database] hvscTop100];
	[songsArray removeAllObjects];
	// grab from PK list
	for ( int i = 0; i < TOP100_COUNT; ++i )
	{
		//NSLog( @"creating song %d", i );
		Song* song = [[app database] getSongByPK:hvscTop100pk[i]];
		assert( song != nil );
		if ([[app offlineMode] boolValue])
		{
			if ([song cached])
			{
				[songsArray addObject:song];
			}
		}
		else
		{
			[songsArray addObject:song];
		}
		[song release];
		
	}

	return songsArray;
}

- (BOOL) rebuildViewNeeded
{
	BOOL refresh =  [[app database] rebuildTop100list];
	[[app database] setRebuildTop100list:NO];
	return refresh;
}

@end
