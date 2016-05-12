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

#import "AppDelegate.h"
#import "PlayerViewController.h"
#import "Song.h"
#import "GLOscillatorView.h"
#import "AutoScrollLabel.h"

#define PREV_TRANSPORT_SECONDS 2

@interface PlayerViewController ()
@end

@implementation PlayerViewController

Sid_MachineAppDelegate* appDelegate;
NSInteger playSeconds;
bool havePrevSong;
float volume[3];
NSUInteger solo;

NSTimer* secondsTimer;
NSTimer* fineTimer;

@synthesize delegate;

@synthesize oscillatorView;
@synthesize oscillatorDisabled;
@synthesize backgroundImage;
@synthesize overviewView;
@synthesize detailView;
@synthesize detailText;
@synthesize actionSheet;
@synthesize progressView;

@synthesize prev;
@synthesize prevSub;
@synthesize pause;
@synthesize play;
@synthesize nextSub;
@synthesize next;

@synthesize position;
@synthesize songname;
@synthesize author;
@synthesize publisher;
@synthesize duration;

@synthesize iButton;
@synthesize toggleFavorite;

@synthesize tweakPosition;

@synthesize v1_volume;
@synthesize v2_volume;
@synthesize v3_volume;
@synthesize v1_mute;
@synthesize v2_mute;
@synthesize v3_mute;
@synthesize v1_solo;
@synthesize v2_solo;
@synthesize v3_solo;

UIView* nextToAnimate;

-(void)viewWillAppear:(BOOL)animated
{
	volume[0] = v1_volume.value;
	volume[1] = v2_volume.value;
	volume[2] = v3_volume.value;
	
	if ([appDelegate.enableOscillator boolValue])
	{
		[oscillatorView startAnimation];
		oscillatorDisabled.hidden = YES;
		oscillatorView.hidden = NO;
	}
	else
	{
		oscillatorDisabled.hidden = NO;
		oscillatorView.hidden = YES;
	}
	
	// start timer for updating the playtime
	if ( secondsTimer == nil )
		secondsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:appDelegate selector:@selector(secondsTimer) userInfo:nil repeats:YES];
	// start timer for updating the position
	fineTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/7.0 target:appDelegate selector:@selector(positionTimer) userInfo:nil repeats:YES];	
}

-(void)viewWillDisappear:(BOOL)animated
{
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSString *finalPath = [path stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary *plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];
	NSString *identifier = [NSString stringWithFormat:@"%@", [plistData objectForKey:@"CFBundleIdentifier"]];
	[plistData release];
	if([identifier compare:@"de.vanille.sidplayer"] == NSOrderedSame)
	{
		[[[self navigationController] navigationBar] setBarStyle:UIBarStyleDefault];
	}
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
												animated:YES ];
	if ( [appDelegate.pauseWhenLeavingPlayer boolValue] )
		[appDelegate doPlayerAction:@"pause"];

	if ([appDelegate.enableOscillator boolValue])
	{
		[oscillatorView stopAnimation];
	}
	
	// Note that we can't disable the seconds timer when this view disappears, since it is responsible
	// for detecting the end of a song / forwarding to the next song.
	[fineTimer invalidate];
}

-(void)viewDidDisappear:(BOOL)animated
{
	// switch back to overview
	detailView.alpha = 0.0;
	overviewView.alpha = 1.0;
	backgroundImage.alpha = 0.5;
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad
{
    [super viewDidLoad];
	NSLog(@"PlayerView did load for the first time.");

	appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];

	// add our custom add button as the nav bar's custom right view
	toggleFavorite = [[[UIBarButtonItem alloc]
					  initWithImage:[UIImage imageNamed:@"star-deselected.png"]
					  style:(UIBarButtonItemStyle) UIBarButtonItemStylePlain
					  target:self
					  action:@selector(toggleFavoriteClicked:)] autorelease];
	self.navigationItem.rightBarButtonItem = toggleFavorite;

	[self reset];
	
	solo = -1;
	
	publisher.textColor = [UIColor whiteColor];
	publisher.font = [UIFont fontWithName:@"Thonburi-Bold" size:16.0];
	
	detailText.font = [UIFont fontWithName:@"Courier-Bold" size:16.0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
	[iButton release];
}

- (void)reset
{
	[pause setEnabled:false];
	[play setEnabled:false];
	[prev setEnabled:false];
	[next setEnabled:false];
	[prevSub setEnabled:false];
	[nextSub setEnabled:false];
	[toggleFavorite setImage: [UIImage imageNamed:@"star-deselected.png"]];
	self.toggleFavorite.enabled = NO;
	self.iButton.hidden = YES;

	[self navigationItem].title = NSLocalizedString(@"Now Playing", @"");

	tweakPosition.value = 0.0;
	position.text = @"";
	[songname setText:@""];
	[author setText:@""];
	[publisher setText:@""];
	[duration setText:@""];
}

#pragma mark -
#pragma mark Interface Builder Action methods

-(IBAction) playPrevSong:(id)sender
{
	if ( !prev.enabled )
		return;
	
	NSLog(@"playPrevSong");
	
	if ( playSeconds > PREV_TRANSPORT_SECONDS )
	{
		// it's not a real prev, just a reset of the current
		[prev setEnabled:havePrevSong];
		[appDelegate doPlayerAction:@"r"];
	}
	else
	{
		[appDelegate doPlayerAction:@"p"];
		[self.delegate newSong:-1];
	}
}

-(IBAction) playPrevSub:(id)sender
{
	if (!prevSub.enabled )
		return;
	
	NSLog(@"playPrevSub");
	[appDelegate doPlayerAction:@"ps"];
}

-(IBAction) pauseMusic:(id)sender
{
	NSLog(@"pause music");
	[appDelegate doPlayerAction:@"pause"];
}

-(IBAction) playMusic:(id)sender
{
	NSLog(@"play music");
	[appDelegate doPlayerAction:@"play"];
}

-(IBAction) resetMusic:(id)sender
{
	NSLog(@"reset music");
	[appDelegate doPlayerAction:@"r"];
}

-(IBAction) playNextSub:(id)sender
{
	if (!nextSub.enabled )
		return;

	NSLog(@"playNextSub");
	[appDelegate doPlayerAction:@"ns"];
}

-(IBAction) playNextSong:(id)sender
{
	if ( !next.enabled )
		return;

	NSLog(@"playNextSong");
	[appDelegate doPlayerAction:@"n"];
	[self.delegate newSong:1];
}

-(void) playNextSongWithoutPlayerWindow
{
	NSLog(@"playNextSongWithoutPlayerWindow");
	[appDelegate doPlayerAction:@"nnw"];
	[self.delegate newSong:1];
}

-(IBAction) tweakPositionHit:(id)sender
{
	NSLog(@"seeking to %.2f", tweakPosition.value);
	[appDelegate seek:tweakPosition.value];
}

-(IBAction) voiceVolumeChanged:(id)sender
{
	NSLog(@"voice volume %p", sender);	
	NSUInteger voice;
	
	if (sender == v1_volume)
		voice = 0;
	else if (sender == v2_volume)
		voice = 1;
	else if (sender == v3_volume)
		voice = 2;
	else
		NSAssert(false, @"slider unknown");
	
	[appDelegate setVolume:((UISlider*)sender).value forVoice:voice];
}

-(IBAction) voiceMuted:(id)sender
{
	NSLog(@"voice mute toggle %p", sender);
	
	NSUInteger voice;
	UISlider* slider;
	
	if (sender == v1_mute)
	{
		slider = v1_volume;
		voice = 0;
	}
	else if (sender == v2_mute)
	{
		voice = 1;
		slider = v2_volume;
	}
	else if (sender == v3_mute)
	{
		voice = 2;
		slider = v3_volume;
	}
	else
		NSAssert(false, @"mute button unknown");
	
	if (slider.enabled == YES)
		[self muteVoice:voice];
	else
		[self unmuteVoice:voice];
}

-(IBAction) voiceSolo:(id)sender
{
	NSLog(@"voice solo %p", sender);

	NSUInteger voice;
	
	if (sender == v1_solo)
	{
		voice = 0;
	}
	else if (sender == v2_solo)
	{
		voice = 1;
	}
	else if (sender == v3_solo)
	{
		voice = 2;
	}
	else
		NSAssert(false, @"mute button unknown");
	
	v1_solo.selected = NO;
	v2_solo.selected = NO;
	v3_solo.selected = NO;

	if ( solo != voice )
	{
		[self soloVoice:voice];
		
		if (voice == 0) v1_solo.selected = YES;
		if (voice == 1) v2_solo.selected = YES;
		if (voice == 2) v3_solo.selected = YES;
	}
	else
	{
		[self unmuteVoice:0];
		[self unmuteVoice:1];
		[self unmuteVoice:2];
		solo = -1;
	}
}

#pragma mark Swapping Views

-(IBAction) iButtonHit:(id)sender
{
	NSLog(@"iButton hit. Swap views now...");
	UIView* toFadeOut = detailView.alpha == 0.0 ? overviewView : detailView;
	nextToAnimate = detailView.alpha == 0.0 ? detailView : overviewView;
	[UIView beginAnimations:nil context:nil]; // begins animation block
	[UIView setAnimationDuration:0.75];        // sets animation duration
	[UIView setAnimationDelegate:self];        // sets delegate for this block
	//[UIView setAnimationDidStopSelector:@selector(finishedFadingOut)];   // calls the finishedFading method when the animation is done (or done fading out)	
	toFadeOut.alpha = 0.0;       // Fades the alpha channel of this view to "0.0" over the animationDuration of "0.75" seconds
	[UIView commitAnimations];   // commits the animation block.  This Block is done.

	[UIView beginAnimations:nil context:nil]; // begins animation block
	[UIView setAnimationDuration:0.75];        // sets animation duration
	nextToAnimate.alpha = 1.0;   // fades the view to 1.0 alpha over 0.75 seconds
	if (backgroundImage.alpha == 0.5)
		backgroundImage.alpha = 0.25; // slightly dim
	else
		backgroundImage.alpha = 0.5;
	[UIView commitAnimations];   // commits the animation block.  This Block is done.
}


-(void) finishedFadingOut
{
	[UIView beginAnimations:nil context:nil]; // begins animation block
	[UIView setAnimationDuration:0.75];        // sets animation duration
	nextToAnimate.alpha = 1.0;   // fades the view to 1.0 alpha over 0.75 seconds

	if (backgroundImage.alpha == 0.5)
		backgroundImage.alpha = 0.25; // slightly dim
	else
		backgroundImage.alpha = 0.5;
	[UIView commitAnimations];   // commits the animation block.  This Block is done.
}

#pragma mark -
#pragma mark Called by AppDelegate

-(void)updateSongInfo:(NSString*)theTitle
		  WithSubtune:(unsigned int)theSubtune
	   WithMaxSubtune:(unsigned int)maxSubtune
		   WithAuthor:(NSString*)theAuthor
		WithPublisher:(NSString*)thePublisher
		WithStilEntry:(NSString*)stilEntry
	 WithHavePrevSong:(bool)havePrev
	 WithHaveNextSong:(bool)haveNext
	   WithIsFavorite:(bool)isFavorite
{
	NSLog(@"updateSongInfo: %@, %@, %@, %u\n%@", theTitle, theAuthor, thePublisher, [stilEntry length], stilEntry);
#if defined(SIDPLAYER) || defined(ATARIPLAYER)
	NSString* fullTitle = [[NSString alloc] initWithFormat:@"%@ (%d/%d)",
					   theTitle,
					   theSubtune,
					   maxSubtune];

	[self navigationItem].title = theTitle;
	[songname setText:fullTitle];
	[fullTitle release];

#else
	[self navigationItem].title = theTitle;
	songname.text = theTitle;
#endif
	[author setText:theAuthor];
	[publisher setText:thePublisher];

    iButton.hidden = ( [stilEntry length] == 0 );
    
	if ( [stilEntry length] > 0 )
	{
		[publisher setText:[NSString stringWithFormat:@"%@ | %@", thePublisher, stilEntry]];
		publisher.bufferSpaceBetweenLabels = 60;
        
		detailText.text = stilEntry;
        
        NSLog(@"iButton hidden = %@", (iButton.hidden == YES) ? @"Yes" : @"No" );
        NSLog(@"overview alphe = %.1f", overviewView.alpha);
        NSLog(@"STIL Text length = %i", [stilEntry length] );

        
		if ( (iButton.hidden == YES) && (overviewView.alpha != 1.0) )
		{
			[self iButtonHit:self];
		}
	}
	
	// sync. button states
	[prevSub setEnabled:(theSubtune>1)];
	[nextSub setEnabled:(maxSubtune>theSubtune)];

	[pause setEnabled:true];
	[play setEnabled:false];
	
	UIImage* favImage;
	if (isFavorite)
		favImage = [UIImage imageNamed:@"star-selected.png"];
	else
		favImage = [UIImage imageNamed:@"star-deselected.png"];
	[toggleFavorite setImage: favImage];
	self.toggleFavorite.enabled = YES;

	havePrevSong = true;
	[prev setEnabled:havePrev];
	[next setEnabled:haveNext];
	[self.delegate startPlayback];
}

-(void)updateDuration:(unsigned int)seconds
	 WithMaxDuration:(unsigned int)maxSeconds
{
	//NSLog(@"updating duration %d/%d seconds", seconds, maxSeconds );
	playSeconds = seconds;
	
	// always set the previous to enabled after a couple of seconds
	if ( playSeconds > PREV_TRANSPORT_SECONDS )
		[prev setEnabled:true];

	unsigned int playingMinutes = seconds / 60;
	unsigned int playingSeconds = seconds % 60;

	if ( maxSeconds > 0 ) /* not unknown */
	{
		unsigned int songMinutes = maxSeconds / 60;
		unsigned int songSeconds = maxSeconds % 60;

		NSString* s = [[NSString alloc] initWithFormat:@"%02d:%02d %02d:%02d", playingMinutes, playingSeconds, songMinutes, songSeconds];
		[duration setText:s];
		[s release];
		
		double actualPosition = (double)seconds / (double)maxSeconds;
		tweakPosition.value = actualPosition;

		if ( seconds >= maxSeconds )
		{
			NSLog(@"song completed. playing next song");
			if ( [appDelegate.automaticPlayNext boolValue] && next.enabled )
				[self playNextSongWithoutPlayerWindow];
			else
			{
				[self resetMusic:self];
				[self pauseMusic:self];
			}
		}
	}
	else
	{
		NSString* s = [[NSString alloc] initWithFormat:@"%02d:%02d unknown", playingMinutes, playingSeconds];
		[duration setText:s];
		[s release];

		// no automatic forward possible
	}

}

-(void)startAnimation
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.actionSheet = [[[UIActionSheet alloc] initWithTitle:@"Downloading data. Please Wait\n\n\n"
													delegate:nil
										   cancelButtonTitle:nil
									  destructiveButtonTitle:nil
										   otherButtonTitles:nil]
						autorelease];
	progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0f, 40.0f, 220.0f, 90.0f)];
	[progressView setProgressViewStyle: UIProgressViewStyleBar];
    [actionSheet addSubview:progressView];
	
    [progressView setProgress:0.0f];
    [actionSheet showInView:self.view];
	progressView.center = CGPointMake(actionSheet.center.x, progressView.center.y);
	[progressView release];
}

-(void)updateAnimation:(NSUInteger)already ofTotal:(NSUInteger)total
{
	float ratio = (float)already / (float)total;
	[self.progressView setProgress:ratio];
}

-(void)stopAnimation
{
	[self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	self.actionSheet = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void) updateTransportButtons:(bool)playing
{
	[pause setEnabled:playing];
	[play setEnabled:!playing];
}

-(void) toggleFavoriteClicked:(id)sender
{
	[appDelegate.database toggleFavorite];
	BOOL isFavorite = [[appDelegate currentSong] favorite];

	UIImage* favImage;
	if (isFavorite)
		favImage = [UIImage imageNamed:@"star-selected.png"];
	else
		favImage = [UIImage imageNamed:@"star-deselected.png"];
	[toggleFavorite setImage: favImage];
	// notify delegate if needed
	if ([(NSObject*) self.delegate respondsToSelector: @selector(favoriteToggle:)])
		[self.delegate favoriteToggle:isFavorite];
}

-(void) soloVoice:(NSUInteger)voice
{
	switch (voice)
	{
		case 0: [self unmuteVoice:0]; [self muteVoice:1]; [self muteVoice:2]; break;
		case 1: [self muteVoice:0]; [self unmuteVoice:1]; [self muteVoice:2]; break;
		case 2: [self muteVoice:0]; [self muteVoice:1]; [self unmuteVoice:2]; break;
		default: NSAssert(false, @"invalid voice value");
	}
	solo = voice;
}

-(void) muteVoice:(NSUInteger)voice
{
	UISlider* slider;
	
	switch (voice)
	{
		case 0: slider = v1_volume; v1_mute.selected = true; break;
		case 1: slider = v2_volume; v2_mute.selected = true; break;
		case 2: slider = v3_volume; v3_mute.selected = true; break;
		default: NSAssert(false, @"invalid voice value");
	}
	
	if (slider.value == 0.0) // already muted
		return;

	volume[voice] = slider.value; // for unmuting
	slider.value = 0.0;
	slider.enabled = NO;
	[appDelegate setVolume:slider.value forVoice:voice];
	NSLog(@"muted voice %d, saved value to restore %.02f", voice, volume[voice]);
}

-(void) unmuteVoice:(NSUInteger)voice
{
	UISlider* slider;
	
	switch (voice)
	{
		case 0: slider = v1_volume; v1_mute.selected = false; break;
		case 1: slider = v2_volume; v2_mute.selected = false; break;
		case 2: slider = v3_volume; v3_mute.selected = false; break;
		default: NSAssert(false, @"invalid voice value");
	}
	
	slider.value = volume[voice];
	slider.enabled = YES;
	[appDelegate setVolume:slider.value forVoice:voice];
	NSLog(@"unmuted voice %d, set to %.02f", voice, slider.value);
}

@end
