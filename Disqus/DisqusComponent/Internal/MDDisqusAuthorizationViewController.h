//
//  MDDisqusAuthorizationViewController.h
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDDisqusComponent.h"

@class MDDisqusAuthorizationViewController;
@protocol MDDisqusAuthorizationViewControllerDelegate <NSObject>

- (void)disqusAuthorizationViewControllerDidCancel:(MDDisqusAuthorizationViewController *)authorizationViewController;
- (void)disqusAuthorizationViewControllerDidFinish:(MDDisqusAuthorizationViewController *)authorizationViewController accessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken error:(NSError *)error;

@end

@interface MDDisqusAuthorizationViewController : UIViewController

- (id)initWithAuthorizationType:(MDDisqusComponentAuthorizationType)authType disqusComponent:(MDDisqusComponent *)disqusComponent;

@property (nonatomic, assign) id <MDDisqusAuthorizationViewControllerDelegate>delegate;

@end
