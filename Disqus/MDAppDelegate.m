//
//  MDAppDelegate.m
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import "MDAppDelegate.h"
#import "MDDisqusComponent.h"

#import "MDThreadsViewController.h"

@implementation MDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
	
	_disqusComponent = [[MDDisqusComponent alloc] initWithPublicKey:@"WIGd3KxBOh9dL4xElmMT187srgiJisi3qE32vH8HMe9REOh1q5frteV8eRbN6UdM" secretKey:@"APreuwmWueMXGVjA6807MjJsZFYb6zZ6inevwy5tJwq5DFUp3lDkb2hLw6b9BhaS" redirectURL:[NSURL URLWithString:@"http://moqod.com"]];
	
	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:[[[MDThreadsViewController alloc] init] autorelease]] autorelease];
	self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

@end
