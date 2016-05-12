//
//  ADBannerTabBarController.h
//  SidPlayer
//
//  Created by Kai Teuber on 10.08.10.
//  Copyright 2010 Lauer, Teuber GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

// UITabBarController that has room for a persistent ad banner above the UITabBar
@interface ADBannerTabBarController : UITabBarController <UITabBarDelegate, ADBannerViewDelegate, UINavigationControllerDelegate>
{
	ADBannerView *adBanner;
	UIView *container;
	CGRect adBannerFrame;
	CGRect containerFrame;
	BOOL	wasPlaying;
}

@property (nonatomic, retain) ADBannerView *adBanner;
@property (nonatomic, retain) UIView *container;
@property (nonatomic) CGRect adBannerFrame;
@property (nonatomic) CGRect containerFrame;

- (void)showAdBanner;
- (void)hideAdBanner;

@end
