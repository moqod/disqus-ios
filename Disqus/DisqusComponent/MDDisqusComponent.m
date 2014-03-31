//
//  MDDisqusComponent.m
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import "MDDisqusComponent.h"
#import "MDDisqusTokensModel.h"
#import "MDDisqusAuthorizationViewController.h"
#import "AFNetworking.h"

// URLs
NSString *const MDDisqusComponentBaseAuthURL				= @"https://disqus.com/api/oauth/2.0/";
NSString *const MDDisqusComponentAuthorizeURL				= @"https://disqus.com/api/oauth/2.0/authorize/";
NSString *const MDDisqusComponentAccessTokenURL				= @"https://disqus.com/api/oauth/2.0/access_token/";
NSString *const MDDisqusComponentAPIURL						= @"https://disqus.com/api/3.0/";

// error domain
NSString *const MDDisqusComponentErrorDomain				= @"MDDisqusComponentErrorDomain";
NSString *const MDDisqusErrorDomain							= @"MDDisqusErrorDomain";

// keys
NSString *const MDDisqusComponentAuthorizationCompletionHandlerKey		= @"MDDisqusComponentAuthorizationCompletionHandlerKey";
NSString *const MDDisqusComponentParentViewControllerKey				= @"MDDisqusComponentParentViewControllerKey";
NSString *const MDDisqusComponentInitialErrorKey						= @"MDDisqusComponentInitialErrorKey";

// typedefs
typedef void (^AFHTTPRequestOperationSuccessCompletion)(AFHTTPRequestOperation *operation, id response);
typedef void (^AFHTTPRequestOperationFailureCompletion)(AFHTTPRequestOperation *operation, NSError *error);

@interface MDDisqusComponent () <MDDisqusAuthorizationViewControllerDelegate>

@property (nonatomic, retain) MDDisqusTokensModel		*tokensModel;

@property (nonatomic, retain) NSString					*publicKey;
@property (nonatomic, retain) NSString					*secretKey;
@property (nonatomic, retain) NSURL						*redirectURL;

@property (nonatomic, copy) AFHTTPRequestOperationSuccessCompletion		operationSuccessCompletion;
@property (nonatomic, copy) AFHTTPRequestOperationFailureCompletion		operationFailureCompletion;

@property (nonatomic, retain) NSMutableArray							*postponedOperations;
@property (nonatomic, assign) BOOL										isRenewingAccessToken;

@property (nonatomic, copy) MDDisqusComponentAuthorizationHandler		authorizationCompletionHandler;
@property (nonatomic, retain) UIViewController							*parentViewController;

@end

@implementation MDDisqusComponent

#pragma mark - public

- (NSString *)disqusPublicKey {
	return self.publicKey;
}

- (NSString *)disqusSecretKey {
	return self.secretKey;
}

- (NSURL *)disqusRedirectURL {
	return self.redirectURL;
}

- (NSString *)accessToken {
	return self.tokensModel.accessToken;
}

- (BOOL)isAuthorized {
	return (self.accessToken != nil);
}

#pragma mark - helpers

- (NSDictionary *)paramsFromQueryString:(NSString *)queryString {
	NSMutableDictionary *paramsDictionary = [NSMutableDictionary dictionary];
    for (NSString *pair in [queryString componentsSeparatedByString:@"&"]) {
		NSArray *keyAndValue = [pair componentsSeparatedByString:@"="];
		if (2 == keyAndValue.count) {
			[paramsDictionary setObject:[keyAndValue objectAtIndex:1] forKey:[keyAndValue objectAtIndex:0]];
		}
    }
	return paramsDictionary;
}

- (NSString *)queryStringFromDictionary:(NSDictionary *)dictionary {
	NSMutableString *queryString = [NSMutableString string];
	BOOL shouldAddAmpersand = NO;
	for (NSString *key in [dictionary allKeys]) {
		[queryString appendFormat:@"%@%@=%@", shouldAddAmpersand ? @"&" : @"", key, [dictionary objectForKey:key]];
		shouldAddAmpersand = YES;
	}
	return queryString;
}

- (NSError *)disqusErrorFromFailedOperation:(AFHTTPRequestOperation *)operation {
	NSError *parsingError = nil;
	NSDictionary *jsonObject = [operation.responseSerializer responseObjectForResponse:operation.response data:operation.responseData error:&parsingError];
	
	// parsing error is not nil => we skip it
	if ([jsonObject isKindOfClass:[NSDictionary class]] && [jsonObject objectForKey:@"code"]) {
		// yeah, disqus error
		NSDictionary *errorUserInfo = nil;
		if (nil != jsonObject[@"response"]) {
			errorUserInfo = [NSDictionary dictionaryWithObject:jsonObject[@"response"] forKey:NSLocalizedDescriptionKey];
		}
		NSInteger errorCode = [[jsonObject objectForKey:@"code"] intValue];
		return [NSError errorWithDomain:MDDisqusErrorDomain code:errorCode userInfo:errorUserInfo];
	} else {
		return nil;
	}
}

#pragma mark -

- (id)initWithPublicKey:(NSString *)publicKey secretKey:(NSString *)secretKey redirectURL:(NSURL *)redirectURL {
	if (!publicKey || !secretKey) {
#if !__has_feature(objc_arc)
		[self autorelease];
#endif
		return nil;
	} else if (self = [super init]) {
		self.publicKey = publicKey;
		self.secretKey = secretKey;
		self.redirectURL = redirectURL;
		self.postponedOperations = [NSMutableArray array];
		
        MDDisqusTokensModel *model = [[MDDisqusTokensModel alloc] initWithPublicKey:publicKey];
#if !__has_feature(objc_arc)
        [model autorelease];
#endif
		self.tokensModel = model;
	}
	return self;
}

- (void)dealloc {
	self.operationFailureCompletion = nil;
	self.operationSuccessCompletion = nil;
	self.parentViewController = nil;
#if !__has_feature(objc_arc)
	[_publicKey release];
	[_secretKey release];
	[_redirectURL release];
	[_authorizationCompletionHandler release];
	[_postponedOperations release];
	[super dealloc];
#endif
}

#pragma mark -

- (void)authorizeModallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler {
	[self authorizeVia:MDDisqusComponentAuthorizationDisqus modallyOnViewController:parentViewController completionHandler:completionHandler];
}

- (void)authorizeVia:(MDDisqusComponentAuthorizationType)authorizationType modallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler {
	self.authorizationCompletionHandler = completionHandler;
	self.parentViewController = parentViewController;
	
	MDDisqusAuthorizationViewController *viewController = [[MDDisqusAuthorizationViewController alloc] initWithAuthorizationType:authorizationType disqusComponent:self];
	viewController.delegate = self;
#if !__has_feature(objc_arc)
    [viewController autorelease];
#endif
	UINavigationController *fakeNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
#if !__has_feature(objc_arc)
    [fakeNavigationController autorelease];
#endif
	[parentViewController presentViewController:fakeNavigationController animated:YES completion:nil];
}

- (void)logout {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	// TODO: check domains list
	NSArray *domains = [NSArray arrayWithObjects:@"disqus.com", @"facebook.com", @"twitter.com", @"google.com", nil];
	NSMutableArray *cookieToBeDeleted = [NSMutableArray array];
	for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
		for (NSString *domain in domains) {
			if ([cookie.domain rangeOfString:domain].location != NSNotFound) {
				[cookieToBeDeleted addObject:cookie];
			}
		}
	}
	
	/*
    NSArray *cookies = [[cookieStorage cookiesForURL:[NSURL URLWithString:MDDisqusComponentBaseAuthURL]] copy];
#if !__has_feature(objc_arc)
    [cookies  autorelease];
#endif
	 */
    for (NSHTTPCookie *cookie in cookieToBeDeleted) {
        [cookieStorage deleteCookie:cookie];
    }
	[self.tokensModel reset];
}

#pragma mark - UIWebViewDelegate

- (void)disqusAuthorizationViewControllerDidCancel:(MDDisqusAuthorizationViewController *)authorizationViewController {
	NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorCancelled userInfo:nil];
	[self performAuthorizationCompletionHandlerWithError:error];
}

- (void)disqusAuthorizationViewControllerDidFinish:(MDDisqusAuthorizationViewController *)authorizationViewController accessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken error:(NSError *)error {
	if (nil != error) {
		[self performAuthorizationCompletionHandlerWithError:error];
	} else {
		self.tokensModel.accessToken = accessToken;
		self.tokensModel.refreshToken = refreshToken;
		[self.tokensModel dump];
		[self performAuthorizationCompletionHandlerWithError:nil];
	}
}

#pragma mark - Access Token

- (void)performAuthorizationCompletionHandlerWithError:(NSError *)error {
	if (self.authorizationCompletionHandler) {
		self.authorizationCompletionHandler(error);
	}
	
	// dismiss modal view controller
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
	
	self.authorizationCompletionHandler = nil;
	self.parentViewController = nil;
}

#pragma mark - Renewing Access Token stuff

- (BOOL)isInvalidAccessTokenError:(NSError *)error {
	return [MDDisqusErrorDomain isEqualToString:error.domain] && MDDisqusErrorAuthorizationSignatureNotValid == error.code;
}

- (void)postponeFailedOperation:(AFHTTPRequestOperation *)operation {
	[self.postponedOperations addObject:operation];
}

- (void)renewAccessToken {
	if (NO == self.isRenewingAccessToken) {
		if (nil != self.tokensModel.refreshToken) {
			self.isRenewingAccessToken = YES;
			// refresh token
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:MDDisqusComponentAccessTokenURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
			NSString *paramsString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=%@&refresh_token=%@", self.publicKey, self.secretKey, @"refresh_token", self.tokensModel.refreshToken];
			request.HTTPBody = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
			request.HTTPMethod = @"POST";
			AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
#if !__has_feature(objc_arc)
			[operation autorelease];
#endif
			operation.responseSerializer = [AFJSONResponseSerializer serializer];
			[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
				if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"access_token"] && [response objectForKey:@"refresh_token"]) {
					self.tokensModel.accessToken = [response objectForKey:@"access_token"];
					self.tokensModel.refreshToken = [response objectForKey:@"refresh_token"];
					[self.tokensModel dump];
					[self enqueuePostponedOperations];
				} else {
					[self logout];
					[self failPostponedOperations];
				}
				self.isRenewingAccessToken = NO;
				
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				[self logout];
				[self failPostponedOperations];
				
				self.isRenewingAccessToken = NO;
			}];
			[operation start];
		} else {
			[self failPostponedOperations];
		}
	}
}

- (void)failPostponedOperations {
	for (AFHTTPRequestOperation *operation in self.postponedOperations) {
		NSError *error = operation.userInfo[MDDisqusComponentInitialErrorKey];
		MDDisqusComponentAPIHandler responseHandler = operation.userInfo[@"handler"];
		if (responseHandler) {
			responseHandler(nil, error ? error : [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorNotAuthorized userInfo:nil]);
		}
	}
	[self.postponedOperations removeAllObjects];
}

- (void)enqueuePostponedOperations {
	for (AFHTTPRequestOperation *operation in self.postponedOperations) {
		[operation start];
	}
	[self.postponedOperations removeAllObjects];
}

#pragma mark - APIs

#pragma mark * common

- (void)innerRequestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler requiresAuth:(BOOL)requiresAuth {
	// check API name
	if (NO == [apiName hasSuffix:@".json"]) {
		apiName = [apiName stringByAppendingString:@".json"];
	}
	
	// setup parameters
	NSMutableDictionary *paramsWithAPIKey = [NSMutableDictionary dictionaryWithDictionary:params];
	[paramsWithAPIKey setValue:self.publicKey forKey:@"api_key"];
	
	if (YES == requiresAuth) {
		[paramsWithAPIKey setValue:self.accessToken forKey:@"access_token"];
	}
	
#ifdef DEBUG
	NSLog(@"%s %@ params == %@", __PRETTY_FUNCTION__, apiName, paramsWithAPIKey);
#endif
	
	// construct URL
	BOOL isGETRequest = [[httpMethod uppercaseString] isEqualToString:@"GET"];
	NSString *apiURLString = [NSString stringWithFormat:@"%@%@", MDDisqusComponentAPIURL, apiName];
	NSURL *apiURL = nil;
	if (isGETRequest) {
		apiURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", apiURLString, [self queryStringFromDictionary:paramsWithAPIKey]]];
	} else {
		apiURL = [NSURL URLWithString:apiURLString];
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
	request.HTTPMethod = httpMethod;
	if (NO == isGETRequest) {
		[request setHTTPBody:[[self queryStringFromDictionary:paramsWithAPIKey] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    dispatch_block_t block = [handler copy];
#if !__has_feature(objc_arc)
	[block autorelease];
#endif
    [userInfo setValue:block forKey:@"handler"];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
#if !__has_feature(objc_arc)
    [operation autorelease];
#endif
	operation.userInfo = userInfo;
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	
	if (!self.operationSuccessCompletion) {
		self.operationSuccessCompletion = ^(AFHTTPRequestOperation *operation, id response) {
			MDDisqusComponentAPIHandler responseHandler = [operation.userInfo objectForKey:@"handler"];
			if (responseHandler) {
				responseHandler(response, nil);
			}
		};
	}
	
	if (!self.operationFailureCompletion) {
		__block MDDisqusComponent *selfPointer = self;
		self.operationFailureCompletion = ^(AFHTTPRequestOperation *operation, NSError *error) {
			BOOL shouldNotifyDelegate = YES;
			// may be it is disqus error
			NSError *disqusError = [selfPointer disqusErrorFromFailedOperation:operation];
			if (nil != disqusError) {
				// yeah, disqus error
				error = disqusError;
				
				if ([selfPointer isInvalidAccessTokenError:error]) {
					AFHTTPRequestOperation *dupOperation = [[AFHTTPRequestOperation alloc] initWithRequest:operation.request];
					NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:operation.userInfo];
					[userInfo setValue:error forKey:MDDisqusComponentInitialErrorKey];
					dupOperation.userInfo = userInfo;
					dupOperation.responseSerializer = [AFJSONResponseSerializer serializer];
					[dupOperation setCompletionBlockWithSuccess:selfPointer.operationSuccessCompletion failure:selfPointer.operationFailureCompletion];
#if !__has_feature(objc_arc)
					[dupOperation autorelease];
#endif
					[selfPointer postponeFailedOperation:dupOperation];
					[selfPointer renewAccessToken];
					shouldNotifyDelegate = NO;
				}
			}
			
			MDDisqusComponentAPIHandler responseHandler = [operation.userInfo objectForKey:@"handler"];
			if (shouldNotifyDelegate && responseHandler) {
				responseHandler(nil, error);
			}
		};
	}
	
	[operation setCompletionBlockWithSuccess:self.operationSuccessCompletion failure:self.operationFailureCompletion];
	[operation start];
}

#pragma mark * non auth

- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler {
	[self requestAPI:apiName params:params httpMethod:@"GET" handler:handler];
}

- (void)requestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler {
	[self innerRequestAPI:apiName params:params httpMethod:httpMethod handler:handler requiresAuth:NO];
}

#pragma mark * auth

- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params handler:(MDDisqusComponentAPIHandler)handler {
	[self authRequestAPI:apiName params:params httpMethod:@"GET" handler:handler];
}

- (void)authRequestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler {
	if (NO == [self isAuthorized]) {
		handler(nil, [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorNotAuthorized userInfo:nil]);
	} else {
		[self innerRequestAPI:apiName params:params httpMethod:httpMethod handler:handler requiresAuth:YES];
	}
}

@end
