//
//  MDNewPostViewController.m
//  Disqus
//
//  Created by Andrew Kopanev on 1/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDNewPostViewController.h"

// tags
const int MDNewPostViewControllerSuccessAlertViewTag					= 1;

@interface MDNewPostViewController () <UIAlertViewDelegate, UITextFieldDelegate> {
	UITextField			*_textField;
}
@property (nonatomic, retain) NSString			*threadId;
@end

@implementation MDNewPostViewController

- (id)initWithThreadId:(NSString *)threadId {
	if (self = [super init]) {
		self.threadId = threadId;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"New post";
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	const CGFloat textFieldWidth = floorf(self.view.bounds.size.width * 0.85f);
	_textField = [[UITextField alloc] initWithFrame:CGRectMake(floorf(self.view.bounds.size.width * 0.5f - textFieldWidth * 0.5f), 150.0f, textFieldWidth, 30.0f)];
	_textField.borderStyle = UITextBorderStyleRoundedRect;
	_textField.returnKeyType = UIReturnKeyDone;
	[self.view addSubview:_textField];
	[_textField becomeFirstResponder];
	
	const CGFloat buttonWidth = 160.0f;
	const CGFloat buttonHeight = 35.0f;
	UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	logoutButton.frame = CGRectMake(floorf(self.view.bounds.size.width * 0.5f - buttonWidth * 0.5f), CGRectGetMaxY(_textField.frame) + 25.0f, buttonWidth, buttonHeight);
	[logoutButton addTarget:self action:@selector(logoutAction) forControlEvents:UIControlEventTouchUpInside];
	[logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
	[self.view addSubview:logoutButton];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addNewPostAction)] autorelease];
}

#pragma mark - actions

- (void)logoutAction {
	[GetAppDelegate().disqusComponent logout];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)addNewPostAction {
	if (_textField.text.length > 0) {
		[_textField resignFirstResponder];
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setValue:_textField.text forKey:@"message"];
		[params setValue:self.threadId forKey:@"thread"];
		[GetAppDelegate().disqusComponent authRequestAPI:@"posts/create" params:params httpMethod:@"POST" handler:^(id response, NSError *error) {
			NSString *message = error ? [error localizedDescription] : @"Your post has been successfully added. The API 'threads/listPosts' can return new posts with some delay, please, stand by!";
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			alertView.tag = error ? 0 : MDNewPostViewControllerSuccessAlertViewTag;
			[alertView show];
		}];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (MDNewPostViewControllerSuccessAlertViewTag == alertView.tag) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self addNewPostAction];
	return YES;
}

#pragma mark -

- (void)dealloc {
	[_textField release];
	[_threadId release];
	[super dealloc];
}

@end
