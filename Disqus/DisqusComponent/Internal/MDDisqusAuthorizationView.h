//
//  MDDisqusAuthorizationView.h
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDDisqusAuthorizationView : UIView

@property (nonatomic, readonly) UIWebView		*webView;

- (void)lockView;
- (void)unlockView;

@end
