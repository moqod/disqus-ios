//
//  MDPostsViewController.m
//  Disqus
//
//  Created by Andrew Kopanev on 1/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDPostsViewController.h"
#import "MDPostCellContentView.h"
#import "MDNewPostViewController.h"

const int MDPostsViewControllerAuthorizationSheetViewTag			= 1;

@interface MDPostsViewController () <UIActionSheetDelegate>

@property (nonatomic, retain) NSString			*threadId;
@property (nonatomic, retain) NSArray			*postsList;

@end

@implementation MDPostsViewController

- (id)initWithThreadId:(NSString *)threadId title:(NSString *)title {
	if (self = [super init]) {
		self.threadId = threadId;
		self.title = title;
	}
	return self;
}

- (void)requestPosts {
	[self showActivityIndicatorView];
	self.postsList = nil;
	[self.tableView reloadData];
	
	[GetAppDelegate().disqusComponent requestAPI:@"threads/listPosts" params:@{@"thread" : self.threadId} handler:^(NSDictionary *response, NSError *error) {
		[self hideActivityIndicatorView];		
		if (nil == error) {
			self.postsList = [response objectForKey:@"response"];
			[self.tableView reloadData];
		} else {
			// TODO: show an alert view
			NSLog(@"%s failed to load posts, error == %@", __PRETTY_FUNCTION__, error);
			[[[[UIAlertView alloc] initWithTitle:nil message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
		}
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.tableFooterView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPostAction)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self requestPosts];
}

#pragma mark - actions

- (void)addNewPostAction {
	if (YES == GetAppDelegate().disqusComponent.isAuthorized) {
		MDNewPostViewController *newpostViewController = [[[MDNewPostViewController alloc] initWithThreadId:self.threadId] autorelease];
		[self.navigationController pushViewController:newpostViewController animated:YES];
	} else {
		UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Disqus", @"Facebook", @"Twitter", @"Google", nil] autorelease];
		actionSheet.tag = MDPostsViewControllerAuthorizationSheetViewTag;
		[actionSheet showInView:self.view];
	}
}

- (void)authorizeVia:(MDDisqusComponentAuthorizationType)authType {
	[GetAppDelegate().disqusComponent authorizeVia:authType modallyOnViewController:self completionHandler:^(NSError *error) {
		if (nil == error) {
			[self addNewPostAction];
		} else {
			[[[[UIAlertView alloc] initWithTitle:nil message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
		}
	}];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	const int cellContentViewTag = 1;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		MDPostCellContentView *contentView = [[[MDPostCellContentView alloc] initWithFrame:cell.contentView.bounds] autorelease];
		contentView.tag = cellContentViewTag;
		[cell.contentView addSubview:contentView];
	}
	
	MDPostCellContentView *contentView = (MDPostCellContentView *)[cell.contentView viewWithTag:cellContentViewTag];
	[contentView setPost:[self.postsList objectAtIndex:indexPath.row]];
	[cell.contentView setNeedsDisplay];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *threadDictionary = [self.postsList objectAtIndex:indexPath.row];
	return [MDPostCellContentView heightForPost:threadDictionary width:tableView.bounds.size.width];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (MDPostsViewControllerAuthorizationSheetViewTag == actionSheet.tag) {
		if (buttonIndex != actionSheet.cancelButtonIndex) {
			[self authorizeVia:buttonIndex];
		}
	}
}

#pragma mark -

- (void)dealloc {
	[_postsList release];
	[_threadId release];
	[super dealloc];
}

@end
