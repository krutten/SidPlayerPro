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

#import "SettingViewController.h"
#import "LicenseViewController.h"
#import "SettingsSlider.h"
#import "AppDelegate.h"

@implementation SettingViewController

#define X_NTSC						[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings NTSC", @""), @"text", \
	@"forceNtscMode", @"source", \
	@"changedNtscMode:", @"action", \
	@"switchButton", @"type", \
	nil]

#define X_SIDMODELL					[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings SID", @""), @"text", \
	@"changedSidModeValue:", @"action", \
	sidModeMultiSelection, @"object", \
	@"multiselection", @"type", \
	nil]

#define X_PERFORMANCE				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings performance", @""), @"text", \
	@"enablePerformanceCheck", @"source", \
	@"changedPerformanceCheck:", @"action" , \
	@"switchButton", @"type", \
	nil]

#define X_OSCILLATOR				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings oscillator", @""), @"text", \
	@"enableOscillator", @"source", \
	@"changedOscillator:", @"action" , \
	@"switchButton", @"type", \
	nil]

#define X_PAUSE					[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings automatic pause", @""), @"text", \
	@"pauseWhenLeavingPlayer", @"source", \
	@"changedPauseWhenLeavingPlayer:", @"action", \
	@"switchButton", @"type", \
	nil]

#define X_AUTO					[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings automatic play next", @""), @"text", \
	@"automaticPlayNext", @"source", \
	@"changedAutomaticPlayNext:", @"action", \
	@"switchButton", @"type", \
	nil]

#define X_LENGTH				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings override songlength", @""), @"text", \
	@"overrideSongLength", @"source", \
	@"changedOverrideSongLength:", @"action", \
	@"switchButton", @"type", \
	nil]

#define X_SONGLENGTHSLIDER		[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings default songlength", @""), @"text", \
	@"defaultSongLength", @"source", \
	[[NSNumber alloc] initWithFloat: 5.0], @"MinimumValue", \
	[[NSNumber alloc] initWithFloat: 600.0], @"MaximumValue", \
	@"changedDefaultSongLengthDone:", @"action1", \
	@"changedDefaultSongLengthSliding:", @"action2", \
	@"slider", @"type", \
	nil]

#define X_SEARCH				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings offline mode", @""), @"text", \
	@"offlineMode", @"source", \
	@"changedOfflineMode:", @"action", \
	@"switchButton", @"type", \
	nil]

#define X_ERASEDOWNLOAD			[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings Erase Download Cache", @""), @"text", \
	@"eraseDownloadCache", @"action", \
	@"button", @"type", \
	nil]

#define X_ERASEPLAYED			[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings Erase Played Songs", @""), @"text", \
	@"erasePlayedSongs", @"action", \
	@"button", @"type", \
	nil]

#define X_HVSCNOTICE			[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings HVSC notice", @""), @"text", \
	@"HvscNoticeViewController", @"viewController", \
	@"HvscNoticeWindow", @"nibfile", \
	@"subview", @"type", \
	nil]

#define X_LICENSE				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings license", @""), @"text", \
	@"LicenseViewController", @"viewController", \
	@"licenseWindow", @"nibfile", \
	@"subview", @"type", \
	nil]

#define X_ABOUT				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings about", @""), @"text", \
	@"AboutViewController", @"viewController", \
	@"AboutViewController", @"nibfile", \
	@"subview", @"type", \
	nil]

#define X_MORE				[NSDictionary dictionaryWithObjectsAndKeys: \
	NSLocalizedString(@"settings more", @""), @"text", \
	@"GetMoreViewController", @"viewController", \
	@"GetMoreViewController", @"nibfile", \
	@"subview", @"type", \
	nil]

#define PLAYERSETTINGS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section player settings", @""), \
	X_NTSC, \
	X_SIDMODELL, \
	X_PERFORMANCE, \
	X_OSCILLATOR, \
	nil]

#if (defined(ATARIPLAYER) || defined(ATARIPLAYERLITE) || defined(MODPLAYER) || defined(MODPLAYERLITE))
#define MISCSETTINGS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section general settings", @""), \
	X_OSCILLATOR, \
	X_AUTO, \
	X_PAUSE, \
	X_LENGTH, \
	X_SONGLENGTHSLIDER, \
	X_SEARCH, \
	X_ERASEPLAYED, \
	X_ERASEDOWNLOAD, \
	nil]
#else
#define MISCSETTINGS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section general settings", @""), \
	X_AUTO, \
	X_PAUSE, \
	X_LENGTH, \
	X_SONGLENGTHSLIDER, \
	X_SEARCH, \
	X_ERASEPLAYED, \
	X_ERASEDOWNLOAD, \
	nil]
#endif

#ifdef SIDPLAYER
 #define INFORMATIONS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section informations", @""), \
	X_MORE, \
	X_ABOUT, \
	X_HVSCNOTICE, \
	X_LICENSE, \
	nil]
#endif

#if defined(ATARIPLAYER) || defined(ATARIPLAYERLITE)
 #define INFORMATIONS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section informations", @""), \
	X_MORE, \
	X_ABOUT, \
	X_LICENSE, \
	nil]
#endif

#if defined(MODPLAYER) || defined(MODPLAYERLITE)
 #define INFORMATIONS				[NSArray arrayWithObjects: \
	NSLocalizedString(@"settings section informations", @""), \
	X_MORE, \
	X_ABOUT, \
	nil]
#endif

#ifdef SIDPLAYER
 #define SECTIONSARRAY				[NSArray arrayWithObjects: \
	PLAYERSETTINGS, \
	MISCSETTINGS, \
	INFORMATIONS, \
	nil]
#else
 #define SECTIONSARRAY				[NSArray arrayWithObjects: \
	MISCSETTINGS, \
	INFORMATIONS, \
	nil]
#endif

@synthesize settingsTableView;
@synthesize settingsSections;

- (void)dealloc {
    [super dealloc];
	[settingsTableView release];
	[sidModeMultiSelection release];
	[settingsSections release];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
}

-(void)viewWillAppear:(BOOL)animated
{
	if (!sidModeMultiSelection)
	{
		sidModeMultiSelection = [[MultiSelectionViewController alloc] initWithNibName:@"MuliSelectionWindow" bundle:nil];
		[sidModeMultiSelection setCurrentValue:app.intSidMode];
		[sidModeMultiSelection setStringArray: [NSArray arrayWithObjects: \
												@"Auto", 
												@"MOS 6581", 
												@"MOS 6581 R3",
												@"MOS 6581 R4",
												@"MOS 6581 Galway",
												@"MOS 8580",
												nil]];
	}
	if (!settingsSections)
		self.settingsSections = [NSArray arrayWithArray:SECTIONSARRAY];
	// rebuild the view now
	[settingsTableView reloadData];
}
 

#pragma mark -
#pragma mark Table view methods
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [settingsSections count];
}

// return the header name for a give section
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSArray* elements = [settingsSections objectAtIndex:section];
	return [elements objectAtIndex:0];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* elements = [settingsSections objectAtIndex:section];
	return [elements count] - 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// find matching section array
	NSArray* sectionArray = [settingsSections objectAtIndex:(indexPath.section)];
	// get requested object to draw
	NSDictionary* settings = [sectionArray objectAtIndex:(indexPath.row +1)];
	NSString* type = [settings objectForKey:@"type"];
	float height = 44.0f;
	
	if (type == @"slider")
	{
		// needs more height
		height = 88.0f;
	}
	
	return height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// find matching section array
	NSArray* sectionArray = [settingsSections objectAtIndex:(indexPath.section)];
	// get requested object to draw
	NSDictionary* settings = [sectionArray objectAtIndex:(indexPath.row +1)];
	NSString* type = [settings objectForKey:@"type"];
    
	Boolean newCell = FALSE;
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:type];
    if (cell == nil) {
		// no cell found, let's create one!
		NSLog(@"No cell found for reuse, let's build one");
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:type] autorelease];
		newCell = TRUE;
	}
	// set some defaults
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[cell setIndentationLevel:0];
	
	// each typ gets drwn different
	if ( type == @"switchButton" )
	{
        [cell.textLabel setText:[settings objectForKey:@"text"]];
        [cell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        
		// cell with a switch to the rigth
		UISwitch* newSwitch = NULL;
		if (newCell)
		{
			newSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(210.0f, 10.0f, 90.0f, 27.0f)];
			[newSwitch setTag:1];
			[cell addSubview: newSwitch];
			[newSwitch release];
		}
		// recover UISwitch from cell
		newSwitch = (UISwitch*) [cell viewWithTag:1];
		// add action method to the switch
		[newSwitch removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
		[newSwitch addTarget:self action:NSSelectorFromString([settings objectForKey:@"action"]) forControlEvents:UIControlEventValueChanged];
		NSString* objName = [settings objectForKey:@"source"];
		NSNumber* value = [self getValue: objName];
		[newSwitch setOn: [value boolValue]];
	}
		
	else if ( type == @"slider" )
	{
		SettingsSlider* sliderView = NULL;
		if (newCell)
		{
			sliderView = [[SettingsSlider alloc]initWithFrame:CGRectMake(20.0f, 0.0f, 280.0f, 88.0f)];
			[sliderView setTag:2];
			[cell addSubview:sliderView];
			[sliderView release];
		}
		sliderView = (SettingsSlider*) [cell viewWithTag:2];

		// some default settings
		[sliderView setContinuous:FALSE];

		// set slider properties
		[sliderView setLabel:[settings objectForKey: @"text"]];

		NSNumber* min = [settings objectForKey:@"MinimumValue"];
		NSNumber* max = [settings objectForKey:@"MaximumValue"];
		NSString* objName = [settings objectForKey:@"source"];
		NSNumber* value = [self getValue: objName];
		[sliderView setMinimumValue:[min floatValue]];
		[sliderView setMaximumValue:[max floatValue]];
		[sliderView setViewValue:value];
		[sliderView setValue:[value integerValue]];

		[sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchDragInside];
		[sliderView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
		[sliderView addTarget:self action:NSSelectorFromString([settings objectForKey:@"action2"]) forControlEvents:UIControlEventTouchDragInside];
		[sliderView addTarget:self action:NSSelectorFromString([settings objectForKey:@"action1"]) forControlEvents:UIControlEventValueChanged];
	}

	else if ( type == @"button" )
	{
		// cell behaving like a button (fake)
		[cell.textLabel setText: [settings objectForKey: @"text"]];
		[cell.textLabel setTextAlignment: UITextAlignmentCenter];
		[cell setSelectionStyle: UITableViewCellSelectionStyleGray];
	}
	
	else if ( type == @"subview" )
	{
		// cell to show another viewcontroller
		[cell.textLabel setText: [settings objectForKey: @"text"]];
		[cell.textLabel setTextAlignment: UITextAlignmentLeft];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setSelectionStyle: UITableViewCellSelectionStyleGray];
	}
	
	else if ( type == @"multiselection" )
	{
		// cell to show another viewcontroller
		[cell.textLabel setText: [settings objectForKey: @"text"]];
		// add value text to view
		UILabel* valueLabel;
		if (newCell)
		{
			valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 7, 125, 27)];
			[valueLabel setTag:6];
			[cell addSubview: valueLabel];
			[valueLabel release];
		}
		// recover UILabel from cell
		valueLabel = (UILabel*) [cell viewWithTag:6];
		
		MultiSelectionViewController* targetViewController = [settings objectForKey:@"object"];
		[valueLabel setText:[targetViewController getCurrentValueString]];
		[valueLabel setTextAlignment: UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:0.75]];
        [valueLabel setBackgroundColor:[UIColor clearColor]];

		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setSelectionStyle: UITableViewCellSelectionStyleGray];
	}
	else
	{
		NSLog(@"Cell to draw, but no type found - Check SettingsArray for nil pointers!");
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// find matching section array
	NSArray* sectionArray = [settingsSections objectAtIndex:(indexPath.section)];
	// get requested object to draw
	NSDictionary* settings = [sectionArray objectAtIndex:(indexPath.row +1)];
	NSString* type = [settings objectForKey:@"type"];

	if ( type == @"button" )
	{
		// let's deselect the cell after a while
		[self performSelector:@selector(deselect:) withObject:nil afterDelay:0.25f];
		// let's build a msg and call it
		SEL action = NSSelectorFromString( [settings objectForKey:@"action"] );
		[self performSelector: action];
	}
	else if ( type == @"subview" )
	{
		// let's deselect the cell after a while
		[self performSelector:@selector(deselect:) withObject:nil afterDelay:0.25f];
		// a subview got pressed, let's find the matching viewcontroller and push it
		UIViewController* targetViewController;
		Class className = NSClassFromString([settings objectForKey:@"viewController"]);
		targetViewController = [[className alloc] initWithNibName:[settings objectForKey:@"nibfile"] bundle:nil];
		[targetViewController.navigationItem setTitle:[settings objectForKey:@"text"]];
		
		UINavigationController* navCon = [self navigationController];
		[navCon pushViewController:targetViewController animated:YES];
		[targetViewController release];
	}

	else if ( type == @"multiselection" )
	{
		// let's deselect the cell after a while
		[self performSelector:@selector(deselect:) withObject:nil afterDelay:0.25f];
		// a subview showing multi selection options -> integer value / string description
		MultiSelectionViewController* targetViewController = [settings objectForKey:@"object"];

		[targetViewController setTarget: self];
		[targetViewController setAction: NSSelectorFromString([settings objectForKey:@"action"])];
		
		[targetViewController.navigationItem setTitle:[settings objectForKey:@"text"]];

		UINavigationController* navCon = [self navigationController];
		[navCon pushViewController:targetViewController animated:YES];

	}
	
	else
	{
		NSLog(@"Cell type is unknown, better do nothing!");
	}
}

// remove cell selection
- (void) deselect: (id) sender
{
	NSLog(@"Deselecting cell");
	[settingsTableView deselectRowAtIndexPath:[settingsTableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark private Action Methods
#pragma mark -

-(void)changedDefaultSongLengthSliding:(id)sender
{
	SettingsSlider* slider = sender;
	int value = slider.value;
	[slider setViewValue:[NSNumber numberWithInt:value]];
}

-(void)changedDefaultSongLengthDone:(id)sender
{
	SettingsSlider* songLengthSlider = sender;
	int value = songLengthSlider.value;
	app.defaultSongLength = [NSNumber numberWithInt:value];
	NSLog(@"changedDefaultSongLength to %i", value);
}


-(void)changedPerformanceCheck:(id)sender
{
	UISwitch* performanceSwitch = sender;
	app.enablePerformanceCheck = [NSNumber numberWithBool:performanceSwitch.on];
	NSLog(@"changedPerformanceCheck to %i", performanceSwitch.on);
}

-(void)changedOscillator:(id)sender
{
	UISwitch* oscillatorSwitch = sender;
	app.enableOscillator = [NSNumber numberWithBool:oscillatorSwitch.on];
	NSLog(@"changedOscillator to %i", oscillatorSwitch.on);
}

-(void)changedOfflineMode:(id)sender
{
	UISwitch* offlineModeSwitch = sender;
	app.offlineMode = [NSNumber numberWithInteger:offlineModeSwitch.on];
	[app notifyOfflineMode];
	
	[app setRestartSearch: YES];
	NSLog(@"changeOfflineMode to %i", offlineModeSwitch.on);
	NSLog(@"Switch at %p", app.offlineMode);
}

-(void)changedOverrideSongLength:(id)sender
{
	UISwitch* overrideSwitch = sender;
	app.overrideSongLength = [NSNumber numberWithBool:overrideSwitch.on];
	NSLog(@"changedOverrideSongLength to %i", overrideSwitch.on);
}

-(void)changedAutomaticPlayNext:(id)sender
{
	UISwitch* automaticSwitch = sender;
	app.automaticPlayNext = [NSNumber numberWithBool:automaticSwitch.on];
	NSLog(@"changedAutomaticPlayNext to %i", automaticSwitch.on);
}

-(void)changedPauseWhenLeavingPlayer:(id)sender
{
	UISwitch* pauseSwitch = sender;
	app.pauseWhenLeavingPlayer = [NSNumber numberWithBool:pauseSwitch.on];
	NSLog(@"changedPauseWhenLeavingPlayer to %i", pauseSwitch.on);
}

-(void)changedNtscMode:(id)sender
{
	UISwitch* HzSwitch = sender;
	app.forceNtscMode = [NSNumber numberWithBool:HzSwitch.on];
	[app restartCurrentSong];
	NSLog(@"changedHzMode to %i", HzSwitch.on);
}

-(void)changedSidModeValue:(id)sender
{
	app.intSidMode = [NSNumber numberWithInt:[[sidModeMultiSelection currentValue] integerValue]];
	NSLog(@"SidMode value did change to: %@", app.intSidMode);
	[app restartCurrentSong];
}

- (void)eraseDownloadCache
{
	NSLog(@"eraseDownloadCache");
	
	EraseDownloadCacheDelegate* delegate = [[EraseDownloadCacheDelegate alloc] init];

	UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Erase dialog text", @"")
													   delegate:delegate
											  cancelButtonTitle:NSLocalizedString(@"Erase button not", @"")
										 destructiveButtonTitle:NSLocalizedString(@"Erase button yes", @"")
											  otherButtonTitles:nil];

	sheet.actionSheetStyle = UIActionSheetStyleDefault;
	sheet.destructiveButtonIndex = 0;
	sheet.cancelButtonIndex = 1;
	
	[sheet showInView:self.view.window];
	[sheet release];
}

- (void)erasePlayedSongs
{
	NSLog(@"erasePlayedSongs");
	
	ErasePlayedSongsDelegate* delegate = [[ErasePlayedSongsDelegate alloc] init];
	UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Erase songs text", @"")
													   delegate:delegate
											  cancelButtonTitle:NSLocalizedString(@"Erase songs not", @"")
										 destructiveButtonTitle:NSLocalizedString(@"Erase songs yes", @"")
											  otherButtonTitles:nil];
	
	sheet.actionSheetStyle = UIActionSheetStyleDefault;
	sheet.destructiveButtonIndex = 0;
	sheet.cancelButtonIndex = 1;
	
	[sheet showInView:self.view.window];
	[sheet release];
}

# pragma mark -
# pragma mark getValue
# pragma mark -

- (NSNumber*) getValue: (NSString*) objName
{
	SEL selector = NSSelectorFromString( objName );
	NSMethodSignature * sig = nil;
	sig = [[app class] instanceMethodSignatureForSelector:selector];

	NSInvocation * myInvocation = nil;
	myInvocation = [NSInvocation invocationWithMethodSignature:sig];
	[myInvocation setTarget:app];
	[myInvocation setSelector:selector];
	
	NSNumber* result = nil;	
	[myInvocation retainArguments];	
	[myInvocation invoke];
	[myInvocation getReturnValue:&result];
	return result;
}

# pragma mark -
# pragma mark Action Sheet Delegates
# pragma mark -

@end

@implementation EraseDownloadCacheDelegate

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	NSLog(@"action on sheet");
	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if (buttonIndex == 0) {
		[app eraseDownloadCache];
	}
	[self release];
	[app notifyOfflineMode];
}

@end

@implementation ErasePlayedSongsDelegate

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	NSLog(@"action on sheet");
	Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	if ( buttonIndex == 0 )
		[app erasePlayedSongs];
	
	[self release];
	[app notifyOfflineMode];	
}

@end
