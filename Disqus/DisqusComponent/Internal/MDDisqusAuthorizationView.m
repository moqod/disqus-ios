//
//  MDDisqusAuthorizationView.m
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDDisqusAuthorizationView.h"
#import <QuartzCore/QuartzCore.h>

@interface MDDisqusAuthorizationView () {
	UIActivityIndicatorView		*_indicatorView;
	NSMutableArray				*_imageViews;
}
@end

@implementation MDDisqusAuthorizationView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		[self addSubview:_webView];
		
		UIImage *wheelImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"disqus_wheel.png" ofType:nil]];
		if (nil == wheelImage) {
			_indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		} else {
			const int imageViewsCount = 3;
			_imageViews = [[NSMutableArray alloc] initWithCapacity:imageViewsCount];
			for (int i = 0; i < imageViewsCount; i++) {
				UIImageView *imageView = [[UIImageView alloc] initWithImage:wheelImage];
				imageView.tag = i;
				[_imageViews addObject:imageView];
				[self addSubview:imageView];
#if !__has_feature(objc_arc)
				[imageView autorelease];
#endif
				CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
				rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * (i % 2 ? 1.0 : -1.0)];
				rotationAnimation.duration = 1.75;
				rotationAnimation.cumulative = YES;
				rotationAnimation.repeatCount = HUGE_VALF;
				
				[imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
			}
		}
    }
    return self;
}

#pragma mark -

- (void)lockView {
	[_webView removeFromSuperview];
	for (UIImageView *imageView in _imageViews) {
		imageView.hidden = NO;
	}
	[self addSubview:_indicatorView];
	[_indicatorView startAnimating];
}

- (void)unlockView {
	[self addSubview:_webView];
	[_indicatorView stopAnimating];
	[_indicatorView removeFromSuperview];
	for (UIImageView *imageView in _imageViews) {
		imageView.hidden = YES;
	}
}

#pragma mark -

- (void)layoutSubviews {
	[super layoutSubviews];
	_webView.frame = self.bounds;
	_indicatorView.center = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
	
	if (_imageViews.count > 0) {
		const CGFloat distanceBetweenWheels = -1.5f;
		UIView *anyWheel = [_imageViews firstObject];
		CGFloat totalWidth = anyWheel.bounds.size.width * _imageViews.count + distanceBetweenWheels * (_imageViews.count - 1);
		CGFloat currentX = ceilf(self.bounds.size.width * 0.5f - totalWidth * 0.5f);
		CGFloat currentY = ceilf(self.bounds.size.height * 0.2f);
		for (UIView *v in _imageViews) {
			v.frame = CGRectMake(currentX, v.tag % 2 ? currentY : currentY - 3.0f, v.bounds.size.width, v.bounds.size.height);
			currentX = CGRectGetMaxX(v.frame) + distanceBetweenWheels;
		}
	}
}

#pragma mark -

- (void)dealloc {
#if !__has_feature(objc_arc)
	[_webView release];
	[_indicatorView release];
	[_imageViews release];
	[super dealloc];
#endif
}

@end
