//
//  NSURL+iCloudBackup.m
//  ModPlayer
//
//  Created by Michael Lauer on 25.06.12.
//  Copyright (c) 2012 Vanille-Media. All rights reserved.
//

#import "NSURL+iCloudBackup.h"

@implementation NSURL (iCloudBackup)

-(BOOL)LT_addSkipBackupAttribute
{
    assert([[NSFileManager defaultManager] fileExistsAtPath:[self path]]);
    
    NSError *error = nil;
    BOOL success = [self setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if ( !success )
    {
        NSLog( @"Error excluding %@ from backup %@", [self lastPathComponent], error );
    }
    return success;
}

@end
