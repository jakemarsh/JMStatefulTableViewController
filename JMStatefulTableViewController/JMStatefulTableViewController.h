//
//  JMStatefulTableViewControllerViewController.h
//  JMStatefulTableViewControllerDemo
//
//  Created by Jake Marsh on 5/3/12.
//  Copyright (c) 2012 Jake Marsh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMStatefulTableViewLoadingView.h"
#import "JMStatefulTableViewEmptyView.h"
#import "JMStatefulTableViewErrorView.h"
#import "SVPullToRefresh.h"

typedef enum {
	JMStatefulTableViewControllerStateIdle = 0,
	JMStatefulTableViewControllerStateInitialLoading = 1,
	JMStatefulTableViewControllerStateLoadingFromPullToRefresh = 2,
	JMStatefulTableViewControllerStateLoadingNextPage = 3,
	JMStatefulTableViewControllerStateEmpty = 4,
	JMStatefulTableViewControllerError = 5,
} JMStatefulTableViewControllerState;

@class JMStatefulTableViewController;

@protocol JMStatefulTableViewControllerDelegate <NSObject>

@required
- (void) statefulTableViewControllerWillBeginInitialLoading:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;

@required
- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(JMStatefulTableViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure;

@required
- (void) statefulTableViewControllerWillBeginLoadingNextPage:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure;

@required
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(JMStatefulTableViewController *)vc;

@optional
- (void) statefulTableViewController:(JMStatefulTableViewController *)vc willTransitionToState:(JMStatefulTableViewControllerState)state;

@optional
- (void) statefulTableViewController:(JMStatefulTableViewController *)vc didTransitionToState:(JMStatefulTableViewControllerState)state;

@optional
- (BOOL) statefulTableViewControllerShouldPullToRefresh:(JMStatefulTableViewController *)vc;

@end

@interface JMStatefulTableViewController : UITableViewController <JMStatefulTableViewControllerDelegate>

@property (nonatomic) JMStatefulTableViewControllerState statefulState;

@property (strong, nonatomic) UIView *emptyView;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UIView *errorView;

@property (nonatomic, unsafe_unretained) id <JMStatefulTableViewControllerDelegate> statefulDelegate;

- (void) loadNewer;

@end