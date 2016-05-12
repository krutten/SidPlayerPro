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
#import "MultiSelectionViewController.h"

@implementation MultiSelectionViewController

@synthesize multiselectionTableView;
@synthesize lastSelection;
@synthesize stringArray;
@synthesize target;
@synthesize action;
@synthesize currentValue;


- (void)dealloc {
    [super dealloc];
	[multiselectionTableView release];
	[lastSelection release];
	[stringArray release];
	[target release];
	[currentValue release];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Table view methods
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger no = [stringArray count];
	if (no > 0) return no;
	else return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MultiSelectionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }

	[cell.textLabel setText:[stringArray objectAtIndex:indexPath.row]];
	[cell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];

	if (indexPath.row ==  [currentValue integerValue])
	{
		[cell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:0.75]];
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		[self setLastSelection: indexPath];
	}

	[cell setSelectionStyle: UITableViewCellSelectionStyleGray];
	[cell setIndentationLevel:0];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath != lastSelection)
	{
		// set checkmark to selected row
		UITableViewCell* newcell = [multiselectionTableView cellForRowAtIndexPath:indexPath];
		[newcell setAccessoryType:UITableViewCellAccessoryCheckmark];
		[newcell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:0.75]];
		// remove checkmark from old row
		UITableViewCell* oldcell = [multiselectionTableView cellForRowAtIndexPath:lastSelection];
		[oldcell setAccessoryType:UITableViewCellAccessoryNone];
		[oldcell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];
		// keep lastSelection
		[self setLastSelection:indexPath];
		// store new index.row value
		currentValue = [NSNumber numberWithInteger:indexPath.row];
	}		

	// call action method set by SettingsViewController
	[target performSelector: action];
	
	// let's deselect the cell after a while
	[self performSelector:@selector(deselect:) withObject:nil afterDelay:0.25f];
}


// remove cell selection
- (void) deselect: (id) sender
{
	NSLog(@"Deselecting cell");
	[multiselectionTableView deselectRowAtIndexPath:[multiselectionTableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark public methods
#pragma mark -

// find matching string for current value
- (NSString*) getCurrentValueString
{
	return [stringArray objectAtIndex: [currentValue integerValue]];
}

@end
