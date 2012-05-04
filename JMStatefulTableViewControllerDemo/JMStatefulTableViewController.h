//
//  JMStatefulTableViewControllerViewController.h
//  JMStatefulTableViewControllerDemo
//
//  Created by Jake Marsh on 5/3/12.
//  Copyright (c) 2012 Rubber Duck Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMStatefulTableViewLoadingView.h"
#import "JMStatefulTableViewEmptyView.h"
#import "SVPullToRefresh.h"

typedef enum {
	JMStatefulTableViewControllerStateIdle = 0,
	JMStatefulTableViewControllerStateInitialLoading = 1,
	JMStatefulTableViewControllerStateLoadingFromPullToRefresh = 2,
	JMStatefulTableViewControllerStateLoadingNextPage = 3,
	JMStatefulTableViewControllerStateEmpty = 4,
	JMStatefulTableViewControllerErrorWhileInitiallyLoading = 5,
} JMStatefulTableViewControllerState;

@class JMStatefulTableViewController;

@protocol JMStatefulTableViewControllerDelegate <NSObject>

@required
- (void) statefulTableViewControllerWillBeginInitialLoading:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(JMStatefulTableViewController *)vc completionBlock:(void (^)(NSArray *indexPaths))success failure:(void (^)(NSError *error))failure;

- (void) statefulTableViewControllerWillBeginLoadingNextPage:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(JMStatefulTableViewController *)vc;

- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (UITableViewCell *) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface JMStatefulTableViewController : UITableViewController <JMStatefulTableViewControllerDelegate>

@property (nonatomic) JMStatefulTableViewControllerState statefulState;

@property (nonatomic, retain) JMStatefulTableViewEmptyView *emptyView;
@property (nonatomic, retain) JMStatefulTableViewLoadingView *loadingView;

@property (nonatomic, assign) NSUInteger hasLoadedLastPage;

@property (nonatomic, assign) id <JMStatefulTableViewControllerDelegate> statefulDelegate;

@end