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
#import "AboutViewController.h"


@implementation AboutViewController

@synthesize	textContent, programInfo;

- (void)viewDidLoad {
	NSLog(@"did load");
	app = (Sid_MachineAppDelegate*) [[UIApplication sharedApplication] delegate];
	
	NSString* path = [[NSBundle mainBundle] bundlePath];
	NSString* finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary* plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];

	NSString* aboutText = [NSString stringWithFormat:@"%@ V%@", app.appName, [plistData objectForKey:@"CFBundleVersion"]];
	[plistData release];
	
	if ([app.appName hasPrefix:@"Sid"])
		aboutText = [aboutText stringByAppendingString:@"\nHVSC V55+PSID"];
	
	[programInfo setText:aboutText];
	[textContent loadHTMLString: NSLocalizedString(@"about credits", @"") baseURL:nil];
}


- (void)dealloc {
	[programInfo release];
	[textContent release];
    [super dealloc];
}


@end
