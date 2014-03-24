//
//  MDDisqusTokensModel.m
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDDisqusTokensModel.h"

// keys
NS_INLINE NSString *MDDisqusTokensModelAccessTokenKeyForPublicKey(NSString *publicKey) {
	return [NSString stringWithFormat:@"%@_%@", @"MDDisqusTokensModelAccessTokenKey", publicKey];
}

NS_INLINE NSString *MDDisqusTokensModelRefreshTokenKeyForPublicKey(NSString *publicKey) {
	return [NSString stringWithFormat:@"%@_%@", @"MDDisqusTokensModelRefreshTokenKey", publicKey];
}

@implementation MDDisqusTokensModel

- (id)initWithPublicKey:(NSString *)publicKey {
	if (self = [super init]) {
		self.publicKey = publicKey;
		self.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:MDDisqusTokensModelAccessTokenKeyForPublicKey(self.publicKey)];
		self.refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:MDDisqusTokensModelRefreshTokenKeyForPublicKey(self.publicKey)];
	}
	return self;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [_accessToken release];
	[_refreshToken release];
	[_publicKey release];
	[super dealloc];
#endif
}

- (void)dump {
	// TODO: store tokens in keychain
	[[NSUserDefaults standardUserDefaults] setValue:self.accessToken forKey:MDDisqusTokensModelAccessTokenKeyForPublicKey(self.publicKey)];
	[[NSUserDefaults standardUserDefaults] setValue:self.refreshToken forKey:MDDisqusTokensModelRefreshTokenKeyForPublicKey(self.publicKey)];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reset {
	self.accessToken = nil;
	self.refreshToken = nil;
	[self dump];
}

@end