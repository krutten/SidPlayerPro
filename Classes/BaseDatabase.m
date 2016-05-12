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

#import "BaseDatabase.h"
#import "AppDelegate.h"
#import "DatabaseManager.h"
#import "FileManager.h"
#import "NSURL+iCloudBackup.h"

extern NSInteger LT_systemVersionAsInteger();

//#define DATABASE_SQL_NAME @""

@interface BaseDatabase ()

-(void)createEditableCopyOfDatabaseIfNeeded;

@end


@implementation BaseDatabase

Sid_MachineAppDelegate*		app;

@synthesize dbName;
@synthesize theLock;
@synthesize paths;
@synthesize documentsDirectory;
@synthesize path;
@synthesize connected;

//Sid_MachineAppDelegate*		app;


- (void)dealloc {
	[dbName release];
	[theLock release];
	[paths release];
	[documentsDirectory release];
	[path release];
	[super dealloc];
}


- (void)initDatabase: (NSString*) dbToName
{
	[self setDbName:dbToName];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	theLock = [[NSLock alloc] init];
	
	// set some variabels
	self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	self.documentsDirectory = [paths objectAtIndex:0];
	self.path = [documentsDirectory stringByAppendingPathComponent:dbName];
	// copy database if needed
	[self createEditableCopyOfDatabaseIfNeeded];
	self.connected = NO;
}


- (void)closeDatabase {
	sqlite3_close(database);
	self.connected = NO;
}

-(void)copyDatabaseToFilesystem
{
	BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *myError;
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbName];
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbName];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&myError];
    if (!success)
    {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [myError localizedDescription]);
    }
	else
    {
		NSLog(@"A brand new database was copied into the documents folder");
        
        if ( LT_systemVersionAsInteger() >= __IPHONE_5_1 )
        {
            NSLog( @"Setting non-backup attribute for new database..." );
            //[[NSURL fileURLWithPath:writableDBPath] LT_addSkipBackupAttribute];
        }
	}
}

- (void) executeScript: (NSString*) fileName
{
	NSData* script = [NSData dataWithContentsOfFile: fileName];
	char* sql = (char*) malloc([script length]);
	[script getBytes:sql];
	
	[self openDatabase];

	[theLock lock];

	int result;
	
	result = sqlite3_exec(database, "BEGIN TRANSACTION;",NULL,NULL,NULL);
	NSLog(@"result: %i", result);
	result = sqlite3_exec(database, sql, NULL, NULL, NULL);
	NSLog(@"result: %i", result);
	result = sqlite3_exec(database, "COMMIT TRANSACTION;",NULL,NULL,NULL);
	NSLog(@"result: %i", result);
	
	[theLock unlock];
	free(sql);
}

#pragma mark -
#pragma mark private methods
#pragma mark -

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbName];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
	[self copyDatabaseToFilesystem];
}

-(void)openDatabase
{
	if (self.connected == NO)
	{
		// open sqlite connection
		if (sqlite3_open([path UTF8String], &database) == SQLITE_OK)
		{
			// connection established
			self.connected = YES;
			if ([self class] == [DatabaseManager class])
				NSLog(@"DatabaseManager:");
			else
				NSLog(@"FileManager:");
			
			NSLog(@"  ...new database connection got established");
		}
		else
		{
			// Even though the open failed, call close to properly clean up resources.
			[self closeDatabase];
//			self.connected = NO;
			NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
		}
	}
}

@end
