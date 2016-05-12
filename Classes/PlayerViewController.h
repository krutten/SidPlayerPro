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

@class EAGLView;
@class AutoScrollLabel;

@protocol CellNotificationDelegate;


@interface PlayerViewController : UIViewController
{
	// delegate to notify the last used tabelcell
	id <CellNotificationDelegate> delegate;
	
	IBOutlet EAGLView*					oscillatorView;
	IBOutlet UILabel*					oscillatorDisabled;

	IBOutlet UIImageView*				backgroundImage;
	IBOutlet UIView*					overviewView;
	IBOutlet UIView*					detailView;
	IBOutlet UITextView*				detailText;

	IBOutlet UILabel*					statusText;
	IBOutlet UIActionSheet*				actionSheet;
	IBOutlet UIProgressView*			progressView;

	IBOutlet UIBarButtonItem*			prev;
	IBOutlet UIBarButtonItem*			prevSub;
	IBOutlet UIBarButtonItem*			pause;
	IBOutlet UIBarButtonItem*			play;
	IBOutlet UIBarButtonItem*			nextSub;
	IBOutlet UIBarButtonItem*			next;

	IBOutlet UILabel*					duration;
	IBOutlet UILabel*					songname;
	IBOutlet UILabel*					author;
	IBOutlet AutoScrollLabel*			publisher;
	IBOutlet UILabel*					position;
	
	IBOutlet UIButton*					iButton;
	UIBarButtonItem*					toggleFavorite;
	
	IBOutlet UISlider*					tweakPosition;
	
	/* Mixer */
	IBOutlet UISlider*					v1_volume;
	IBOutlet UISlider*					v2_volume;
	IBOutlet UISlider*					v3_volume;
	
	IBOutlet UIButton*					v1_mute;
	IBOutlet UIButton*					v2_mute;
	IBOutlet UIButton*					v3_mute;

	IBOutlet UIButton*					v1_solo;
	IBOutlet UIButton*					v2_solo;
	IBOutlet UIButton*					v3_solo;
	
}
-(IBAction) playNextSong:(id)sender;
-(IBAction) playNextSub:(id)sender;
-(IBAction) playPrevSong:(id)sender;
-(IBAction) playPrevSub:(id)sender;
-(IBAction) playMusic:(id)sender;
-(IBAction) pauseMusic:(id)sender;
-(IBAction) resetMusic:(id)sender;
-(IBAction) iButtonHit:(id)sender;

-(IBAction) tweakPositionHit:(id)sender;

-(IBAction) voiceVolumeChanged:(id)sender;
-(IBAction) voiceMuted:(id)sender;
-(IBAction) voiceSolo:(id)sender;

-(void) startAnimation;
-(void)updateAnimation:(NSUInteger)already ofTotal:(NSUInteger)total;
-(void) stopAnimation;
-(void) updateTransportButtons:(bool)playing;
-(void) soloVoice:(NSUInteger)voice;
-(void) muteVoice:(NSUInteger)voice;
-(void) unmuteVoice:(NSUInteger)voice;

@property (nonatomic, assign) id <CellNotificationDelegate> delegate;

@property (nonatomic, retain) EAGLView*					oscillatorView;
@property (nonatomic, retain) UILabel*					oscillatorDisabled;
@property (nonatomic, retain) UIImageView*				backgroundImage;
@property (nonatomic, retain) UIView*					overviewView;
@property (nonatomic, retain) UIView*					detailView;
@property (nonatomic, retain) UIView*					loadingView;
@property (nonatomic, retain) UITextView*				detailText;
@property (nonatomic, retain) UIActivityIndicatorView*	activityIndicator;
@property (nonatomic, retain) UIActionSheet*			actionSheet;
@property (nonatomic, retain) UIProgressView*			progressView;

@property (nonatomic, retain) UIBarButtonItem*			prev;
@property (nonatomic, retain) UIBarButtonItem*			prevSub;
@property (nonatomic, retain) UIBarButtonItem*			pause;
@property (nonatomic, retain) UIBarButtonItem*			play;
@property (nonatomic, retain) UIBarButtonItem*			nextSub;
@property (nonatomic, retain) UIBarButtonItem*			next;

@property (nonatomic, retain) UILabel*					position;
@property (nonatomic, retain) UILabel*					songname;
@property (nonatomic, retain) UILabel*					author;
@property (nonatomic, retain) AutoScrollLabel*			publisher;
@property (nonatomic, retain) UILabel*					duration;

@property (nonatomic, retain) UIButton*					iButton;
@property (nonatomic, retain) UIBarButtonItem*			toggleFavorite;

@property (nonatomic, retain) UISlider*					tweakPosition;

@property (nonatomic, retain) UISlider*					v1_volume;
@property (nonatomic, retain) UISlider*					v2_volume;
@property (nonatomic, retain) UISlider*					v3_volume;

@property (nonatomic, retain) UIButton*					v1_mute;
@property (nonatomic, retain) UIButton*					v2_mute;
@property (nonatomic, retain) UIButton*					v3_mute;

@property (nonatomic, retain) UIButton*					v1_solo;
@property (nonatomic, retain) UIButton*					v2_solo;
@property (nonatomic, retain) UIButton*					v3_solo;	

-(void)updateSongInfo:(NSString*)theTitle
		  WithSubtune:(unsigned int)theSubtune
	   WithMaxSubtune:(unsigned int)maxSubtune
		   WithAuthor:(NSString*)theAuthor
		WithPublisher:(NSString*)thePublisher
		WithStilEntry:(NSString*)stilEntry
	 WithHavePrevSong:(bool)havePrev
	 WithHaveNextSong:(bool)haveNext
	   WithIsFavorite:(bool)isFavorite;

-(void)updateDuration:(unsigned int)seconds
	  WithMaxDuration:(unsigned int)maxSeconds;

-(void) playNextSongWithoutPlayerWindow;

-(void) reset;

@end


@protocol CellNotificationDelegate 

- (void) newSong: (NSInteger) offset;
- (void) startPlayback;
@optional
- (void) favoriteToggle: (BOOL) favorite;

@end;
