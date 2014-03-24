//
//  MDDisqusComponent.h
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDDisqusConstants.h"

typedef NS_ENUM(NSInteger, MDDisqusComponentAuthorizationType) {
    MDDisqusComponentAuthorizationDisqus = 0,
    MDDisqusComponentAuthorizationFacebook,
    MDDisqusComponentAuthorizationTwitter,
    MDDisqusComponentAuthorizationGoogle,
};

typedef void(^MDDisqusComponentAPIHandler)(id response, NSError *error);
typedef void(^MDDisqusComponentAuthorizationHandler)(NSError *error);

@interface MDDisqusComponent : NSObject

@property (nonatomic, readonly) NSString		*disqusPublicKey;
@property (nonatomic, readonly) NSString		*disqusSecretKey;
@property (nonatomic, readonly) NSURL			*disqusRedirectURL;

@property (nonatomic, readonly) NSString		*accessToken;
@property (nonatomic, readonly) BOOL			isAuthorized;

// initializer
- (id)initWithPublicKey:(NSString *)publicKey secretKey:(NSString *)secretKey redirectURL:(NSURL *)redirectURL;

// authorize using MDDisqusComponentAuthorizationDisqus auth type
- (void)authorizeModallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler;

// authorize using provided auth type
- (void)authorizeVia:(MDDisqusComponentAuthorizationType)authorizationType modallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler;

// logs user out
- (void)logout;

// APIs
- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler;
- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler;

- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler;
- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler;

@end
