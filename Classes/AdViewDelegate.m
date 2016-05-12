//
//  AdViewDelegate.m
//  SidPlayer
//
//  Created by Kai Teuber on 10.08.10.
//  Copyright 2010 Lauer, Teuber GbR. All rights reserved.
//

#import "AdViewDelegate.h"


@implementation AdViewDelegate

#pragma mark ADBannerViewDelegate
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	NSLog(@"New Ad Banner got loaded");
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	NSLog(@"iAd will take over, now!");
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	NSLog(@"Banner View did finish");
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	NSLog(@"iAd sent an error....");
}


@end
