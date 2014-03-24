//
//  MDDisqusAuthorizationViewController.m
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDDisqusAuthorizationViewController.h"
#import "MDDisqusAuthorizationView.h"
#import "AFHTTPRequestOperation.h"

// auth URIs
NSString *const MDDisqusComponentAuthorizeViaDisqusURL = @"http://disqus.com/next/login/";
NSString *const MDDisqusComponentAuthorizeViaDisqusCompleteURL = @"http://disqus.com/next/login-success/";

NSString *const MDDisqusComponentAuthorizeViaFacebookURL = @"http://disqus.com/_ax/facebook/begin/";
NSString *const MDDisqusComponentAuthorizeViaFacebookCompleteURL = @"http://disqus.com/_ax/facebook/complete/";

NSString *const MDDisqusComponentAuthorizeViaTwitterURL = @"http://disqus.com/_ax/twitter/begin/";
NSString *const MDDisqusComponentAuthorizeViaTwitterCompleteURL = @"http://disqus.com/_ax/twitter/complete/";

NSString *const MDDisqusComponentAuthorizeViaGoogleURL = @"http://disqus.com/_ax/google/begin/";
NSString *const MDDisqusComponentAuthorizeViaGoogleCompleteURL = @"http://disqus.com/_ax/google/complete/";


@interface MDDisqusAuthorizationViewController () <UIWebViewDelegate> {
	MDDisqusAuthorizationView		*_authorizationView;
}

@property (nonatomic, retain) MDDisqusComponent							*disqusComponent;
@property (nonatomic, assign) MDDisqusComponentAuthorizationType		authorizationType;
@property (nonatomic, assign) BOOL										loggedInViaSocialNetwork;

@end

@implementation MDDisqusAuthorizationViewController

#pragma mark - helpers

- (NSString *)authorizationTypeTitle:(MDDisqusComponentAuthorizationType)authType {
	switch (authType) {
		case MDDisqusComponentAuthorizationFacebook:
			return @"Facebook";
		case MDDisqusComponentAuthorizationTwitter:
			return @"Twitter";
		case MDDisqusComponentAuthorizationGoogle:
			return @"Google";
		default:
			return @"Disqus";
	}
}

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

- (NSURL *)disqusAuthorizationURL {
	NSString *params = [NSString stringWithFormat:@"client_id=%@&scope=read,write&response_type=code&redirect_uri=%@", self.disqusComponent.disqusPublicKey, self.disqusComponent.disqusRedirectURL.absoluteString];
	NSURL *authorizeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", MDDisqusComponentAuthorizeURL, params]];
	return authorizeURL;
}

#pragma mark -

- (id)initWithAuthorizationType:(MDDisqusComponentAuthorizationType)authType disqusComponent:(MDDisqusComponent *)disqusComponent {
	if (self = [super init]) {
		self.disqusComponent = disqusComponent;
		self.authorizationType = authType;
		self.title = [self authorizationTypeTitle:authType];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	_authorizationView = [[MDDisqusAuthorizationView alloc] initWithFrame:self.view.bounds];
	_authorizationView.webView.delegate = self;
	[self.view addSubview:_authorizationView];
	
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAuthorizationAction)];
#if !__has_feature(objc_arc)
    [barButtonItem autorelease];
#endif
	self.navigationItem.rightBarButtonItem = barButtonItem;
	
	// authorize!
    NSURL *authorizeURL = nil;
    switch (self.authorizationType) {
        case MDDisqusComponentAuthorizationFacebook: {
            authorizeURL = [NSURL URLWithString:MDDisqusComponentAuthorizeViaFacebookURL];
            break;
		}
        case MDDisqusComponentAuthorizationTwitter: {
            authorizeURL = [NSURL URLWithString:MDDisqusComponentAuthorizeViaTwitterURL];
            break;
		}
        case MDDisqusComponentAuthorizationGoogle: {
            authorizeURL = [NSURL URLWithString:MDDisqusComponentAuthorizeViaGoogleURL];
            break;
		}
        default: {
			authorizeURL = [self disqusAuthorizationURL];
			break;
		}
    }
	[_authorizationView.webView loadRequest:[NSURLRequest requestWithURL:authorizeURL]];
}

#pragma mark - actions

- (void)cancelAuthorizationAction {
	[self.delegate disqusAuthorizationViewControllerDidCancel:self];
}

- (void)failWithError:(NSError *)error {
	_authorizationView.webView.delegate = nil;
	[self.disqusComponent logout];
	[self.delegate disqusAuthorizationViewControllerDidFinish:self accessToken:nil refreshToken:nil error:error];
}

- (void)finishWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken {
	_authorizationView.webView.delegate = nil;
	[self.delegate disqusAuthorizationViewControllerDidFinish:self accessToken:accessToken refreshToken:refreshToken error:nil];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[_authorizationView lockView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if (YES == self.loggedInViaSocialNetwork) {
		// reset flag
		self.loggedInViaSocialNetwork = NO;
		
		// TODO: find the problem
		// delay added because webview fails redirect
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5), dispatch_get_main_queue(), ^(void){
			NSURL *authorizeURL = [NSURL URLWithString:MDDisqusComponentAuthorizeViaDisqusURL];
			[webView loadRequest:[NSURLRequest requestWithURL:authorizeURL]];
        });
	} else {
		[_authorizationView unlockView];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (([error.domain isEqualToString:NSURLErrorDomain] && NSURLErrorCancelled == error.code) || ([error.domain isEqualToString:@"WebKitErrorDomain"] && 102 == error.code)) {
		// ignore these errors...
	} else {
		[_authorizationView unlockView];
		[self failWithError:error];
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (YES == [request.URL.host isEqualToString:self.disqusComponent.disqusRedirectURL.host]) {
		NSDictionary *params = [self paramsFromQueryString:request.URL.query];
		if ([params objectForKey:@"code"]) {
			[_authorizationView lockView];
			_authorizationView.webView.delegate = nil;
			[self requestAccessToken:[params objectForKey:@"code"]];
		} else {
			// TODO: parse disqus response error (error parameter name)
			NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorWebViewAuthorizationFailed userInfo:nil];
			[self failWithError:error];
		}
		return NO;
	} else if([request.URL.absoluteString hasPrefix:MDDisqusComponentAuthorizeViaDisqusCompleteURL]) {
		NSURL *authorizeURL = [self disqusAuthorizationURL];
		webView.delegate = nil;
		[webView stopLoading];
		webView.delegate = self;
		[webView loadRequest:[NSURLRequest requestWithURL:authorizeURL]];
	} else if([request.URL.absoluteString hasPrefix:MDDisqusComponentAuthorizeViaFacebookCompleteURL] || [request.URL.absoluteString hasPrefix:MDDisqusComponentAuthorizeViaTwitterCompleteURL] || [request.URL.absoluteString hasPrefix:MDDisqusComponentAuthorizeViaGoogleCompleteURL]) {
		self.loggedInViaSocialNetwork = YES;
	}
	return YES;
}

#pragma mark - access token

- (void)requestAccessToken:(NSString *)requestToken {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:MDDisqusComponentAccessTokenURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
	NSString *paramsString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=%@&redirect_uri=%@&code=%@", self.disqusComponent.disqusPublicKey, self.disqusComponent.disqusSecretKey, @"authorization_code", self.disqusComponent.disqusRedirectURL, requestToken];
	request.HTTPBody = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
	request.HTTPMethod = @"POST";
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
#if !__has_feature(objc_arc)
    [operation autorelease];
#endif
	operation.responseSerializer = [AFJSONResponseSerializer serializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
		if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"access_token"] && [response objectForKey:@"refresh_token"]) {
			[self finishWithAccessToken:[response objectForKey:@"access_token"] refreshToken:[response objectForKey:@"refresh_token"]];
		} else {
			NSError *error = [NSError errorWithDomain:MDDisqusComponentErrorDomain code:MDDisqusComponentErrorWebViewAuthorizationFailed userInfo:nil];
			[self failWithError:error];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[self failWithError:error];
	}];
	[operation start];
}

#pragma mark - memory management

- (void)dealloc {
	self.disqusComponent = nil;
#if !__has_feature(objc_arc)
	[_authorizationView release];
	[super dealloc];
#endif
}

@end
