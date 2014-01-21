//
//  MDThreadsViewController.m
//  Disqus
//
//  Created by Andrew Kopanev on 1/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDThreadsViewController.h"
#import "MDPostsViewController.h"

@interface MDThreadsViewController ()

@property (nonatomic, copy) NSString			*forumShortname;
@property (nonatomic, retain) NSArray			*threadsList;

@end

@implementation MDThreadsViewController

#pragma mark -

- (id)initWithForumShortname:(NSString *)forumShortname {
	if (self = [super init]) {
		self.forumShortname = forumShortname;
	}
	return self;
}

#pragma mark -

- (void)requestThreadsList {
	[self showActivityIndicatorView];
	
	assert( self.forumShortname != nil );
	
	[GetAppDelegate().disqusComponent requestAPI:@"threads/list" params:@{@"forum" : self.forumShortname} handler:^(NSDictionary *response, NSError *error) {
		[self hideActivityIndicatorView];		
		if (nil == error) {
			self.threadsList = [response objectForKey:@"response"];
			[self.tableView reloadData];
		} else {
			// TODO: show an alert view
			NSLog(@"%s failed to load threads, error == %@", __PRETTY_FUNCTION__, error);
			[[[[UIAlertView alloc] initWithTitle:nil message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
		}
	}];
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = self.forumShortname;
	self.clearsSelectionOnViewWillAppear = YES;
	self.tableView.tableFooterView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	[self requestThreadsList];
}

- (void)dealloc {
	[_threadsList release];
	[_forumShortname release];
	[super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.threadsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
		cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];
		cell.detailTextLabel.textColor = [UIColor grayColor];
	}
	
	NSDictionary *threadDictionary = [self.threadsList objectAtIndex:indexPath.row];
	cell.textLabel.text = [threadDictionary objectForKey:@"title"];
	cell.detailTextLabel.text = [threadDictionary objectForKey:@"link"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *threadDictionary = [self.threadsList objectAtIndex:indexPath.row];
	MDPostsViewController *viewController = [[[MDPostsViewController alloc] initWithThreadId:[threadDictionary objectForKey:@"id"] title:[threadDictionary objectForKey:@"title"]] autorelease];
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
