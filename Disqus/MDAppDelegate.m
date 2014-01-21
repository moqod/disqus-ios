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
	
	NSString *publicKey = @"WIGd3KxBOh9dL4xElmMT187srgiJisi3qE32vH8HMe9REOh1q5frteV8eRbN6UdM";
	NSString *secretKey = @"APreuwmWueMXGVjA6807MjJsZFYb6zZ6inevwy5tJwq5DFUp3lDkb2hLw6b9BhaS";
	NSString *redirectURLString = @"http://moqod.com";
	
	_disqusComponent = [[MDDisqusComponent alloc] initWithPublicKey:publicKey secretKey:secretKey redirectURL:[NSURL URLWithString:redirectURLString]];
	
	NSString *forumShortname = @"moqodtest";
	MDThreadsViewController *threadsViewController = [[[MDThreadsViewController alloc] initWithForumShortname:forumShortname] autorelease];
	UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:threadsViewController] autorelease];
	self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

@end
