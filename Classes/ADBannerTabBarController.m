//
//  ADBannerTabBarController.m
//  SidPlayer
//
//  Created by Kai Teuber on 10.08.10.
//  Copyright 2010 Lauer, Teuber GbR. All rights reserved.
//

#import "ADBannerTabBarController.h"
#import "AppDelegate.h"

@interface ADBannerTabBarController (Private)

- (void)removeBannerFromView;

@end


@implementation ADBannerTabBarController

@synthesize adBanner;
@synthesize delegate;
@synthesize container;
@synthesize containerFrame;
@synthesize adBannerFrame;

- (void)dealloc
{
	adBanner.delegate = nil;
	[adBanner release];
	[container release];
	[super dealloc];
}

#pragma mark ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	NSLog(@"iAd banner view did load");
	[self showAdBanner];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	NSLog(@"iAd will take over, now!");

	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[appDelegate doPlayerAction:@"pause"];
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	NSLog(@"iAd banner lef");
	Sid_MachineAppDelegate* appDelegate = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	[appDelegate doPlayerAction:@"play"];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
//	NSLog(@"iAd error: %@", [error localizedFailureReason]);
	[self hideAdBanner];
}

#pragma mark UIView

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.delegate = self;
    
	self.adBanner = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 480, 320, 50)];
	adBanner.delegate = self;
	
	self.adBannerFrame = adBanner.frame;
	
	// A UITabBarController's view has two subviews: the UITabBar and a container UITransitionView that is
	// used to hold the child views. Save a reference to the container.
	for (UIView *view in self.view.subviews) {
		if (![view isKindOfClass:[UITabBar class]]) {
			self.container = view;
			self.containerFrame = view.frame;
		}
	}

	// we need to get callbacks from NavigationViewController
    for ( UIViewController* controller in self.viewControllers )
    {
        if ( [controller isKindOfClass:[UINavigationController class]] )
        {
            [(UINavigationController*) controller setDelegate:self];
        }
    }
	self.adBanner.hidden = YES;
}

- (void)viewDidUnload {
	self.adBanner = nil;
	self.delegate = nil;
	self.container = nil;
	[super viewDidUnload];
}

#pragma mark UINavigationControllerDelegate
static BOOL navigationControllerDidHideUs = NO;
static float animDelay = 0.10;

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ((!viewController.hidesBottomBarWhenPushed) && (!adBanner.hidden))
	{
		CGFloat containerHeight = containerFrame.size.height;
		CGFloat adBannerHeight = adBannerFrame.size.height;
		container.frame = CGRectMake(0.0,0.0,320.0,containerHeight - adBannerHeight);
		adBanner.frame = CGRectMake(0.0,containerHeight - adBannerHeight,320.0,adBannerHeight);
	}
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ( navigationControllerDidHideUs == viewController.hidesBottomBarWhenPushed ) return;
	
    if ( viewController.hidesBottomBarWhenPushed )
    {
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationDelay:animDelay];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
        navigationControllerDidHideUs = YES;
		adBanner.frame = CGRectMake(-320.0,adBanner.frame.origin.y, adBanner.frame.size.width, adBanner.frame.size.height);
		[UIView commitAnimations];
//        adBanner.hidden = YES;
//        navigationControllerDidHideUs = YES;
    }
    else
    {
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationDelay:animDelay];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
        navigationControllerDidHideUs = NO;
		adBanner.frame = CGRectMake(0.0,adBanner.frame.origin.y, adBanner.frame.size.width*1, adBanner.frame.size.height);
		[UIView commitAnimations];
//        adBanner.hidden = NO;
//        navigationControllerDidHideUs = NO;
    }
}


#pragma mark Methods

- (void)showAdBanner
{
    if ( navigationControllerDidHideUs ) return;

	CGFloat containerHeight = containerFrame.size.height;
	CGFloat adBannerHeight = adBannerFrame.size.height;
	[self.view insertSubview:adBanner belowSubview:self.tabBar];

	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	
	// Resize the frame of the container to add space for the ad banner
	container.frame = CGRectMake(0.0,0.0,320.0,containerHeight - adBannerHeight);
	
	// Place the ad banner above the tab bar but below the container
	adBanner.frame = CGRectMake(0.0,containerHeight - adBannerHeight,320.0,adBannerHeight);
	adBanner.hidden = NO;
	[UIView commitAnimations];
}

- (void)hideAdBanner
{
	CGFloat containerHeight = containerFrame.size.height;
	CGFloat adBannerHeight = adBannerFrame.size.height;

	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	// Resize the frame of the container to take up all available space
	container.frame = CGRectMake(0.0,0.0,320.0,containerHeight + adBannerHeight);

	// Place the ad banner above the tab bar but below the container
	adBanner.frame = CGRectMake(0.0,containerHeight + adBannerHeight,320.0,adBannerHeight);

	[UIView commitAnimations];
	[self performSelector:@selector(removeBannerFromView) withObject:nil afterDelay:1.1];

}

- (void)removeBannerFromView
{
	adBanner.hidden = YES;
	[adBanner removeFromSuperview];
}
@end
