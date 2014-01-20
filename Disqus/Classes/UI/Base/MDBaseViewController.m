//
//  MDBaseViewController.m
//  Disqus
//
//  Created by Andrew Kopanev on 1/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "MDBaseViewController.h"

@interface MDBaseViewController () {
	UIActivityIndicatorView			*_indicatorView;
}

@end

@implementation MDBaseViewController

#pragma mark -

- (void)showActivityIndicatorView {
	if (!_indicatorView) {
		_indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	}
	[_indicatorView startAnimating];
	[self.tableView addSubview:_indicatorView];
}

- (void)hideActivityIndicatorView {
	[_indicatorView stopAnimating];
	[_indicatorView removeFromSuperview];
}

#pragma mark -

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	_indicatorView.center = CGPointMake(self.tableView.bounds.size.width * 0.5f, self.tableView.bounds.size.height * 0.1f);
}

#pragma mark -

- (void)dealloc {
	[_indicatorView release];
	[super dealloc];
}

@end
