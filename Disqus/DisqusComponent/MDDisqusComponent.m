//
//  MDDisqusComponent.m
//  Disqus
//
//  Created by Andrew Kopanev on 12/24/13.
//  Copyright (c) 2013 Moqod. All rights reserved.
//

#import "MDDisqusComponent.h"
#import "AFNetworking.h"

// keys
NS_INLINE NSString *MDDisqusTokensModelAccessTokenKeyForPublicKey(NSString *publicKey) {
	return [NSString stringWithFormat:@"%@_%@", @"MDDisqusTokensModelAccessTokenKey", publicKey];
}

NS_INLINE NSString *MDDisqusTokensModelRefreshTokenKeyForPublicKey(NSString *publicKey) {
	return [NSString stringWithFormat:@"%@_%@", @"MDDisqusTokensModelRefreshTokenKey", publicKey];
}

@interface MDDisqusTokensModel : NSObject

@property (nonatomic, retain) NSString		*accessToken;
@property (nonatomic, retain) NSString		*refreshToken;
@property (nonatomic, retain) NSString		*publicKey;

- (id)initWithPublicKey:(NSString *)publicKey;
- (void)dump;
- (void)reset;

@end

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
	[_accessToken release];
	[_refreshToken release];
	[_publicKey release];
	[super dealloc];
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

// URLs
NSString *const MDDisqusComponentBaseAuthURL				= @"https://disqus.com/api/oauth/2.0/";
NSString *const MDDisqusComponentAuthorizeURL				= @"https://disqus.com/api/oauth/2.0/authorize/";
NSString *const MDDisqusComponentAccessTokenURL				= @"https://disqus.com/api/oauth/2.0/access_token/";
NSString *const MDDisqusComponentAPIURL						= @"https://disqus.com/api/3.0/";

// error domain
NSString *const MDDisqusComponentErrorDomain				= @"MDDisqusComponentErrorDomain";

// keys
NSString *const MDDisqusComponentAuthorizationCompletionHandlerKey		= @"MDDisqusComponentAuthorizationCompletionHandlerKey";
NSString *const MDDisqusComponentParentViewControllerKey				= @"MDDisqusComponentParentViewControllerKey";

@interface MDDisqusComponent () <UIWebViewDelegate>

@property (nonatomic, retain) MDDisqusTokensModel		*tokensModel;

@property (nonatomic, retain) NSString					*publicKey;
@property (nonatomic, retain) NSString					*secretKey;
@property (nonatomic, retain) NSURL						*redirectURL;

@property (nonatomic, copy) MDDisqusComponentAuthorizationHandler		authorizationCompletionHandler;
@property (nonatomic, retain) UIViewController							*parentViewController;

@end

@implementation MDDisqusComponent

#pragma mark - public

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

#pragma mark -

- (id)initWithPublicKey:(NSString *)publicKey secretKey:(NSString *)secretKey redirectURL:(NSURL *)redirectURL {
	if (!publicKey || !secretKey) {
		[self autorelease];
		return nil;
	} else if (self = [super init]) {
		self.publicKey = publicKey;
		self.secretKey = secretKey;
		self.redirectURL = redirectURL;
		
		self.tokensModel = [[[MDDisqusTokensModel alloc] initWithPublicKey:publicKey] autorelease];
	}
	return self;
}

- (void)dealloc {
	[_publicKey release];
	[_secretKey release];
	[_redirectURL release];
	[_authorizationCompletionHandler release];
	[super dealloc];
}

#pragma mark -

- (void)authorizeModallyOnViewController:(UIViewController *)parentViewController completionHandler:(MDDisqusComponentAuthorizationHandler)completionHandler {
	self.authorizationCompletionHandler = completionHandler;
	self.parentViewController = parentViewController;
	
    NSString *params = [NSString stringWithFormat:@"client_id=%@&scope=read,write&response_type=code&redirect_uri=%@", self.publicKey, self.redirectURL.absoluteString];
	NSURL *authorizeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", MDDisqusComponentAuthorizeURL, params]];

	UIViewController *viewController = [[[UIViewController alloc] init] autorelease];
	viewController.title = @"Disqus";
	UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.delegate = self;
	viewController.view = webView;
	
	UINavigationController *fakeNavigationController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
	[webView loadRequest:[NSURLRequest requestWithURL:authorizeURL]];
	viewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAuthorizationAction)] autorelease];
	[parentViewController presentViewController:fakeNavigationController animated:YES completion:nil];
}

- (void)logout {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [[[cookieStorage cookiesForURL:[NSURL URLWithString:MDDisqusComponentBaseAuthURL]] copy] autorelease]) {
        [cookieStorage deleteCookie:cookie];
    }
	[self.tokensModel reset];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (YES == [request.URL.host isEqualToString:self.redirectURL.host]) {
		NSDictionary *params = [self paramsFromQueryString:request.URL.query];
		if ([params objectForKey:@"code"]) {
			[self requestAccessToken:[params objectForKey:@"code"]];
		} else {
			// TODO: parse disqus response error (error parameter name)
			NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorWebViewAuthorizationFailed userInfo:nil];
			[self performAuthorizationCompletionHandlerWithError:error];
		}
		return NO;
	} else {
		return YES;
	}
	return YES;
}

- (void)cancelAuthorizationAction {
	NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorCancelled userInfo:nil];
	[self performAuthorizationCompletionHandlerWithError:error];
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

- (void)requestAccessToken:(NSString *)requestToken {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:MDDisqusComponentAccessTokenURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
	NSString *paramsString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=%@&redirect_uri=%@&code=%@", self.publicKey, self.secretKey, @"authorization_code", self.redirectURL, requestToken];
	request.HTTPBody = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
	request.HTTPMethod = @"POST";
	AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
		if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"access_token"] && [response objectForKey:@"refresh_token"]) {
			self.tokensModel.accessToken = [response objectForKey:@"access_token"];
			self.tokensModel.refreshToken = [response objectForKey:@"refresh_token"];
			[self.tokensModel dump];
			[self performAuthorizationCompletionHandlerWithError:nil];
		} else {
			NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorWebViewAuthorizationFailed userInfo:nil];
			[self performAuthorizationCompletionHandlerWithError:error];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self performAuthorizationCompletionHandlerWithError:error];
	}];
	[operation start];
}

#pragma mark - APIs

#pragma mark * common

- (void)innerRequestAPI:(NSString *)apiName params:(NSDictionary *)params httpMethod:(NSString *)httpMethod handler:(MDDisqusComponentAPIHandler)handler requiresAuth:(BOOL)requiresAuth {
	// check api name
	if (NO == [apiName hasSuffix:@".json"]) {
		apiName = [apiName stringByAppendingString:@".json"];
	}
	
	// setup parameters
	NSMutableDictionary *paramsWithAPIKey = [NSMutableDictionary dictionaryWithDictionary:params];
	[paramsWithAPIKey setValue:self.publicKey forKey:@"api_key"];
		
	if (YES == requiresAuth) {
		[paramsWithAPIKey setValue:self.accessToken forKey:@"access_token"];
	}
	
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
	[userInfo setValue:[handler copy] forKey:@"handler"];
	AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
	operation.userInfo = userInfo;
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
		MDDisqusComponentAPIHandler responseHandler = [operation.userInfo objectForKey:@"handler"];
		if (responseHandler) {
			responseHandler(response, nil);
		}
		[responseHandler release];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		MDDisqusComponentAPIHandler responseHandler = [operation.userInfo objectForKey:@"handler"];
		if (responseHandler) {
			// TODO: put response JSON there
			// AFNetworking does not parse JSON when request failed (stupid!)
			responseHandler(nil, error);
		}
		[responseHandler release];
	}];
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
