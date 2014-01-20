//
//  MDDisqusComponent.h
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MDDisqusComponentAPIHandler)(id response, NSError *error);
typedef void(^MDDisqusComponentAuthorizationHandler)(NSError *error);

extern NSString *const MDDisqusComponentErrorDomain;

typedef NS_ENUM(NSUInteger, MDDisqusComponentError) {
	MDDisqusComponentErrorNotAuthorized					= 1,
	MDDisqusComponentErrorWebViewAuthorizationFailed,
	MDDisqusComponentErrorCancelled
};

@interface MDDisqusComponent : NSObject

@property (nonatomic, readonly) NSString		*accessToken;
@property (nonatomic, readonly) BOOL			isAuthorized;

// initializer
- (id)initWithPublicKey:(NSString *)publicKey secretKey:(NSString *)secretKey redirectURL:(NSURL *)redirectURL;

// auth
- (void)authorizeModallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler;

- (void)logout;

// APIs
- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler;
- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler;

- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler;
- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler;

@end
