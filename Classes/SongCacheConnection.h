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

@protocol SongCacheConnectionDelegate;

@interface SongCacheConnection : NSObject
{
	id <SongCacheConnectionDelegate> delegate;
	NSString* sourcePath; // URL will be <mirror>/<path>
	NSString* destinationPath; // filesystem path
	NSNumber* fileSize; // file size hint (optional)
	NSMutableData *receivedData;
	NSDate *lastModified;
	bool preloading;
	bool external;
	unsigned int mirrorIndex;	
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString* sourcePath;
@property (nonatomic, retain) NSString* destinationPath;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSNumber* fileSize;
@property (nonatomic, retain) NSDate *lastModified;
@property (nonatomic) bool preloading;
@property (nonatomic) bool external;
@property (nonatomic) unsigned int mirrorIndex;

- (id) initWithPath:(NSString*)thePath
		destination:(NSString*)theDestinationPath
		   sizeHint:(NSUInteger)theSizeHint
		  delegate:(id<SongCacheConnectionDelegate>)theDelegate
        preloading:(bool)isPreloading
	externalServer:(bool)externalServer;

+ (void) addMirror:(NSString*)mirror;

@end


@protocol SongCacheConnectionDelegate<NSObject>

- (void) connectionDidFail:(SongCacheConnection*)theConnection;
- (void) connectionDidFinish:(SongCacheConnection*)theConnection;
- (void) connectionProgress:(SongCacheConnection*)theConnection
				haveAlready:(NSUInteger)already
					ofTotal:(NSUInteger)total;
@end
