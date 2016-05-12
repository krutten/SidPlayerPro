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

#import "GetMoreViewController.h"
#import "GetMoreCell.h"

#define	kIconUrl	@"http://www.thrust.de/iPhone/appicons/%@"
#define kPlistUrl	@"http://www.thrust.de/iPhone/MoreApps.plist"

@implementation GetMoreViewController

@synthesize getProgramms;

static NSMutableDictionary* cache = nil;

-(void)viewWillAppear:(BOOL)animated
{
	if ( cache == nil )
	{
		cache = [[NSMutableDictionary dictionaryWithCapacity:10] retain]; // will never be released
	}
	
	if (self.getProgramms == nil)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		self.getProgramms = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:kPlistUrl]];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		if ( self.getProgramms == nil )
		{
			NSString* path = [[NSBundle mainBundle] bundlePath];
			NSString* finalPath = [path stringByAppendingPathComponent:@"MoreApps.plist"];
			self.getProgramms = [NSArray arrayWithContentsOfFile:finalPath];
		}
	}
}

#pragma mark Table view methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexpPath
{
	return 63;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.getProgramms count];
}

-(UIImage*)cachedImageForUrl:(NSString*)url
{
	UIImage* iconImage = [cache objectForKey:url];
	if ( iconImage == nil )
	{
		iconImage = [UIImage imageNamed:@"icon_dummy.png"];
		[cache setValue:iconImage forKey:url];
		[self performSelectorInBackground:@selector(downloadImageForUrl:) withObject:url];
	}
	return iconImage;
}

-(void)downloadImageForUrl:(NSString*)url
{
	UIImage* icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
	[cache setValue:icon forKey:url];
	[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSDictionary* prgInfo = [self.getProgramms objectAtIndex:indexPath.row];
	
	NSString* cellIdentifyer = @"GetMoreCellIdentifier";
	GetMoreCell* cell = (GetMoreCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifyer];
	if (cell == nil)
	{
		NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"GetMoreCell"
													 owner:self
												   options:nil];
		cell = [nib objectAtIndex:0];
	}
	cell.name.text = [prgInfo objectForKey:@"text"];
	NSString* url = [NSString stringWithFormat:kIconUrl, [prgInfo objectForKey:@"icon"]];
	cell.icon.image = [self cachedImageForUrl:url];
	cell.description.text = [prgInfo objectForKey:@"description"];	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSDictionary* prgInfo = [self.getProgramms objectAtIndex:indexPath.row];
	NSURL* url = [NSURL URLWithString: [prgInfo objectForKey:@"url"]];
	
	NSLog(@"Scheme: %@", url.scheme);
	if([url.scheme compare:@"file"] == NSOrderedSame)
		NSLog(@"local load");
	else if ([url.scheme compare:@"http"] == NSOrderedSame)
		[[UIApplication sharedApplication] openURL:url];

}

- (void)dealloc {
	[getProgramms release];
    [super dealloc];
}


@end

