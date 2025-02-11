//
//  STKAdBanner.m
//  Strik
//
//  Created by Nils Wiersema on Mar 21, 2014.
//  Copyright (c) 2014 Strik. All rights reserved.
//

#import "STKAdvertisementBottomBar.h"

#import "STKScene.h"

@interface STKAdvertisementBottomBar()

@property UIView* adView;
@property(readonly,nonatomic) STKScene* parentScene;

@end

@implementation STKAdvertisementBottomBar

- (id)init
{
	if(self = [super init])
	{
		// Set needed content size for this banner type (100% width, 50px high)
		self.contentSizeType = CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitPoints);
		self.contentSize = CGSizeMake(1, 50);
	}
	
	return self;
}

#pragma mark Banner Management

- (void)rotateToNextNetwork
{
	// Clear old ad
	[self clearBanner];
	
	// Rotate to the next ad impl and store the view
	self.adView = [self pickNextBanner];
	if(self.adView)
	{
		NSLog(@"%@: next = %@", self, [self.adView class]);
	}
	else
	{
		NSLog(@"%@: next = NULL", self);
	}
}

- (UIView*)pickNextBanner
{
	// Always use iAd
	return [self createAppleBanner];
}

- (void)bannerDidLoad
{
	// Hurray!
	NSLog(@"%@: successfully loaded %@!", self, [self.adView class]);
	
	// Show the view!
	[[[CCDirector sharedDirector] view] addSubview:self.adView];
	
	// Force position update (positions the view)
	self.position = self.position;
}

- (void)bannerDidNotLoad
{
	// Boo!
	NSLog(@"%@: meh, %@ did not load!", self, [self.adView class]);
	
	// Next network in x seconds!
	[self scheduleOnce:@selector(rotateToNextNetwork) delay:1.0];
}

- (void)clearBanner
{
	if(self.adView)
	{
		[self.adView removeFromSuperview];
		
		self.adView = nil;
	}
}

#pragma mark cocos2d

- (void)onEnter
{
	[super onEnter];
	
	// I'm just a placeholder
	super.visible = NO;
	
	// Here comes the ad
	[self rotateToNextNetwork];
}

- (void)removeFromParent
{
	[super removeFromParent];
	
	[self clearBanner];
}

#pragma mark cocos2d node properties
- (BOOL)visible
{
	return !self.adView.hidden;
}

- (void)setVisible:(BOOL)visible
{
	self.adView.hidden = !visible;
}

- (void)setOpacity:(CGFloat)opacity
{
	self.adView.alpha = opacity;
}

- (CGFloat)opacity
{
	return self.adView.alpha;
}

- (void)setPosition:(CGPoint)position
{
	[super setPosition:position];
	
	if(self.adView)
	{
		// Get ad + win size
		CGSize adSize = self.adView.frame.size;
		CGSize winSize = self.adView.superview.bounds.size;
		
		// Convert between UI and GL space
		CGPoint point = CGPointMake(position.x, (winSize.height - adSize.height - position.y));
		self.adView.frame = CGRectMake(point.x, point.y, adSize.width, adSize.height);
	}
}

- (NSString*)description
{
	STKScene* parentScene = self.scene.children[0];
	
	return [NSString stringWithFormat:@"%@ (%@)", [self class], [parentScene class]];
}

#pragma mark Apple iAd Banners
- (ADBannerView*)createAppleBanner
{
	ADBannerView* appleBanner = [ADBannerView new];
	appleBanner.delegate = self;
	
	return appleBanner;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	/*
	 This method is triggered when an advertisement could not be loaded from the iAds system (perhaps due to a network connectivity issue). If you have already taken steps to only display an ad when it has successfully loaded it is not typically necessary to implement the code for this method. */
	
	[self bannerDidNotLoad];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	/* Introduced as part of the iOS 5 SDK, this method is triggered when the banner confirms that an advertisement is available but before the ad is downloaded to the device and is ready for presentation to the user. */
	
	[self bannerDidLoad];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	/*
	 This method is triggered when the user touches the iAds banner in your application. If the willLeave argument passed through to the method is YES then your application will be placed into the background while the user is taken elsewhere to interact with or view the ad. If the argument is NO then the ad will be superimposed over your running application in which case the code in this method may optionally suspend the screen output until the user returns.
	 
	 f the ad places the application into the background, the application will be resumed automatically once the action is completed.
	 To prevent the ad from performing the action, return NO from this method, though it is strongly recommended by Apple that you return YES if you wish to earn advertising revenue. */
	
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	/* This method is called when the ad view removes the ad content currently obscuring the application interface. If the application was paused during the ad view session this method can be used to resume activity: */
	
	NSLog(@"%@: finished viewing! (iAd)", self);
}

@end
