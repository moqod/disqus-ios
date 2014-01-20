//
//  MDAppDelegate.h
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDDisqusComponent.h"

@interface MDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow					*window;
@property (nonatomic, readonly) MDDisqusComponent		*disqusComponent;

@end
