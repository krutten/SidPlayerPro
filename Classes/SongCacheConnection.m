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

#import "SongCacheConnection.h"

@interface SongCacheConnection (Private)

- (void) launchConnection;
@end

#define SERVER_TIMEOUT 5

@implementation SongCacheConnection

@synthesize delegate;
@synthesize sourcePath;
@synthesize destinationPath;
@synthesize fileSize;
@synthesize receivedData;
@synthesize lastModified;
@synthesize preloading;
@synthesize external;
@synthesize mirrorIndex;

static NSMutableArray* mirrors;

+ (void) addMirror:(NSString*)mirror
{
	if ( !mirrors )
		mirrors = [[NSMutableArray alloc] init];
	
	NSLog(@"SongCacheConnection:addMirror: adding http mirror URL: %@", mirror);
	[mirrors addObject:mirror];
}

- (id) initWithPath:(NSString*)thePath
		destination:(NSString*)theDestinationPath
		   sizeHint:(NSUInteger)theSizeHint
		  delegate:(id<SongCacheConnectionDelegate>)theDelegate
	    preloading:(bool)isPreloading
	externalServer:(bool)externalServer

{
	if (self = [super init])
	{
		self.sourcePath = thePath;
		self.destinationPath = theDestinationPath;
		if (theSizeHint > 0)
			self.fileSize = [[NSNumber alloc]initWithInteger:theSizeHint];
		self.delegate = theDelegate;
		self.preloading = isPreloading;
		self.external = externalServer;

		self.mirrorIndex = externalServer ? [mirrors count]-2 : 0; // start downloading from first mirror
	}
	
	[self launchConnection];	
	return self;
}

- (void) launchConnection
{
	NSString* fullPath;

	if ( self.mirrorIndex >= [mirrors count] )
	{
		NSLog(@"SongCacheConnection:launchConnection: no more mirrors. Download for %@ failed.", self.sourcePath);
		[self.delegate connectionDidFail:self];
		return;
	}
	
	if ( self.external )
	{
		NSLog(@"SongCacheConnection:launchConnection: attempting to download from external URI %@", self.sourcePath);
		fullPath = self.sourcePath;
	}
	else
	{
		NSString* mirror = [mirrors objectAtIndex:self.mirrorIndex];
		NSLog(@"SongCacheConnection:launchConnection: trying mirror #%d -> %@", self.mirrorIndex, mirror);
		fullPath = [mirror stringByAppendingPathComponent:self.sourcePath];
	}

	CFStringRef preprocessedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)fullPath, CFSTR(""), CFSTR(""), kCFStringEncodingUTF8);
	NSLog(@"preprocessed path = %@", preprocessedString);
	NSURL* fullURL = [NSURL URLWithString:(NSString*)preprocessedString];
	[(NSString*)preprocessedString release];
	NSLog(@"SongCacheConnection:launchConnection: full url = %@", fullURL);

	NSURLRequest *theRequest = [NSURLRequest requestWithURL:fullURL
												cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
											timeoutInterval:SERVER_TIMEOUT];
		
	receivedData = [[NSMutableData alloc] initWithLength:0];

	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest 
																	  delegate:self 
															  startImmediately:YES];
	if (connection == nil)
	{
		/* inform the user that the connection failed */
		NSString *message = NSLocalizedString (@"Unable to initiate request.", 
											   @"NSURLConnection initialization method failed.");
		//FIXME notify user
		//SongCacheAlertWithMessage(message);
		NSLog( @"%@", message );
	}
}

- (void)dealloc
{
	[sourcePath release];
	[destinationPath release];
	[fileSize release];
	[receivedData release];
	[lastModified release];
	[super dealloc];
}


#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
	
	if ( [response expectedContentLength] != -1 )
	{
		NSLog(@"SongCacheConnection:didReceiveResponse: expected content length %ld, overriding size hint %ld", [response expectedContentLength], [self.fileSize integerValue] );
		self.fileSize = [NSNumber numberWithLongLong:[response expectedContentLength]];
	}
	
	if ( [response respondsToSelector:@selector(statusCode)] )
	{
		int statusCode = [response statusCode];
		NSLog(@"SongCacheConnection:didReceiveResponse: got status code %d", statusCode );
		if (statusCode == 404)
		{				
			self.mirrorIndex++;
			// Cancel connection, otherwise we may receive data from the 404 page ;)
			[connection cancel];
			[connection release];
			[self launchConnection];
		}
	}
	
	// gather size (if available) from header
	
	if ([response isKindOfClass:[NSHTTPURLResponse self]])
	{
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		for ( NSString* key in [headers allKeys] )
			NSLog(@"got header: '%@' = '%@'", key, [headers objectForKey:key]);
	}
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
	if (!self.preloading && self.fileSize != nil)
	{
		[self.delegate connectionProgress:self haveAlready:[self.receivedData length] ofTotal:[fileSize integerValue]];
	}
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"SongCacheConnection:didFailWithError: %@", error);
	[connection release];
	self.mirrorIndex++;
	[self launchConnection];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	/* this application does not use a NSSongCache disk or memory cache */
    return nil;
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSInteger length = [self.receivedData length];
	NSLog(@"SongCacheConnection:connectionDidFinishLoading: got %d bytes", length);
	if ( !length )
	{
		[connection release];
		return;
	}
	
	NSLog(@"SongCacheConnection:connectionDidFinishLoading: checking data integrity...");
#ifdef SIDPLAYER
	const char* bytes = (const char*) [self.receivedData mutableBytes];
	if ( strcmp( bytes, "PSID" ) != 0 && strcmp( bytes, "RSID" ) != 0 )
	{
		NSLog(@"    data corrupt!");
		[connection release];
		self.mirrorIndex++;
		[self launchConnection];
		return;
	}
	NSLog(@"    integrity verified: %c%c%c%c v%d", bytes[0], bytes[1], bytes[2], bytes[3], bytes[5]);
#endif
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:self.destinationPath] == NO )
	{
		// file doesn't exist, so create it
		[[NSFileManager defaultManager] createFileAtPath:self.destinationPath
												contents:self.receivedData
											  attributes:nil];
	}
	
	[connection release];
	[self.delegate connectionDidFinish:self];
}

@end
