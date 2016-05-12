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

#import "FileManager.h"
#import "AppDelegate.h"

@interface FileManager ()

- (void*) loadFileIntoMemory: (NSString*) filename;

@end

@implementation FileManager

Sid_MachineAppDelegate*		app;

@synthesize fileCount;

long lastFileLength;


- (void)initDatabase: (NSString*)dbToName
{
	[super initDatabase:dbToName];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
}

- (NSInteger) count
{
	return [self.fileCount integerValue];
}

- (void) countInDatabase
{
	int idFound;
	[self openDatabase];
	const char* sql = "SELECT COUNT() FROM Files";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		idFound = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	self.fileCount = [[NSNumber alloc] initWithInteger:idFound];
}

- (bool) isFilesInDb:(int)pk
{
	int idFound;
	[self openDatabase];
	const char* sql = "SELECT COUNT(ID) FROM Files WHERE ID = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pk);
		sqlite3_step(statement);
		idFound = sqlite3_column_int(statement, 0);
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	return (bool) idFound;
}

- (NSData*) openFile:(int)pk
{
	NSLog(@"try to open a file from DB");
	NSData* buffer;

	[self openDatabase];
	const char* sql = "SELECT ID, data FROM Files WHERE ID = ?";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, pk);
		sqlite3_step(statement);
		buffer = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, 1) length:sqlite3_column_bytes(statement, 1)];
		sqlite3_finalize(statement);
	}
	[theLock unlock];
	return buffer;
}

- (void) saveFile:(int)pk
{
	NSString* fileName = [[NSString alloc] initWithFormat:@"%d", pk];
	NSString* destination = [app.dataPath stringByAppendingPathComponent:fileName];
	void* blob = [self loadFileIntoMemory: destination];
	
	if (blob != NULL)
	{
		[self openDatabase];
		const char *sql = "INSERT INTO Files (ID, Data) VALUES (?, ?)";
		sqlite3_stmt *statement;
		[theLock lock];
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
			sqlite3_bind_int(statement, 1, pk);
			sqlite3_bind_blob(statement, 2, blob, lastFileLength, NULL);
			sqlite3_step(statement);
			sqlite3_finalize(statement);
			NSLog(@"Insert für %i in FileDb ausgeführt!", pk);
			int value = [self.fileCount integerValue];
			value++;
			self.fileCount = [[NSNumber alloc] initWithInteger:value];
		}
		[theLock unlock];
		free(blob);
	}
	else
	{
		NSLog(@"Error while loadingFile into Memory");
	}

	[fileName release];
}

- (void) deleteAllFiles
{
	[self openDatabase];
	const char* sql = "DELETE FROM Files";
	sqlite3_stmt *statement;
	[theLock lock];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_step(statement);
		sqlite3_finalize(statement);
		self.fileCount = [[NSNumber alloc] initWithInteger:0];
	}
	[theLock unlock];
}

#pragma mark -
#pragma mark private methods
#pragma mark -

- (void*) loadFileIntoMemory: (NSString*) filename
{
	/* declare a file pointer */
	char cfileName[512];
	[filename getCString:cfileName maxLength:512 encoding:NSASCIIStringEncoding];
	FILE    *infile;
	char    *buffer;
	long    numbytes;
	
	/* open an existing file for reading */
	infile = fopen( cfileName, "r");
	
	/* quit if the file does not exist */
	if(infile == NULL)
		return NULL;
	
	/* Get the number of bytes */
	fseek(infile, 0L, SEEK_END);
	numbytes = ftell(infile);
	
	/* reset the file position indicator to 
	 the beginning of the file */
	fseek(infile, 0L, SEEK_SET);	
	
	/* grab sufficient memory for the 
	 buffer to hold the text */
	buffer = (char*)calloc(numbytes, sizeof(char));	
	
	/* memory error */
	if(buffer == NULL)
		return NULL;
	
	/* copy all the text into the buffer */
	fread(buffer, sizeof(char), numbytes, infile);
	fclose(infile);
	lastFileLength = numbytes;
	return buffer;
}


@end
