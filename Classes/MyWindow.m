//
//  SidPlayerPro
//
//  Created by Dr. Michael Lauer on 22.04.10.
//

#import "MyWindow.h"
#import "AppDelegate.h"

@implementation MyWindow

-(void) makeKeyAndVisible
{
    [super makeKeyAndVisible];
    
	if ( [[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)] )
	{
		NSLog( @"iPhone OS 4 detected; listening to remote control events" );
		[self becomeFirstResponder];
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	}
	else
	{
		NSLog( @"iPhone OS 3 (or older) detected; not listening to remote control events" );
	}
}

#pragma mark -
#pragma mark Motion
#pragma mark -

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake)
	{
		//FIXME: toggle play/pause
	}
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

#pragma mark -
#pragma mark Remote Control
#pragma mark -

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	Sid_MachineAppDelegate* d = (Sid_MachineAppDelegate*) [[UIApplication sharedApplication]delegate];
	[d remoteControlReceivedWithEvent:event];
}

@end
