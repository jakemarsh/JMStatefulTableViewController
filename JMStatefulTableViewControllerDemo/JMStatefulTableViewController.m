//
//  JMStatefulTableViewControllerViewController.m
//  JMStatefulTableViewControllerDemo
//
//  Created by Jake Marsh on 5/3/12.
//  Copyright (c) 2012 Rubber Duck Software. All rights reserved.
//

#import "JMStatefulTableViewController.h"

static const int kLoadingCellTag = 257;

@interface JMStatefulTableViewController ()

@property (nonatomic, assign) BOOL isCountingRows;

// Loading

- (void) _loadFirstPage;
- (void) _loadNextPage;

- (void) _loadFromPullToRefresh;

// Table View Cells & NSIndexPaths

- (UITableViewCell *) _cellForLoadingCell;
- (BOOL) _indexRepresentsLastSection:(NSInteger)section;
- (BOOL) _indexPathRepresentsLastRow:(NSIndexPath *)indexPath;
- (NSInteger) _totalNumberOfRows;
- (CGFloat) _cumulativeHeightForCellsAtIndexPaths:(NSArray *)indexPaths;

@end

@implementation JMStatefulTableViewController

@synthesize statefulState = _statefulState;

@synthesize loadingView = _loadingView;
@synthesize emptyView = _emptyView;

@synthesize statefulDelegate = _statefulDelegate;

@synthesize isCountingRows = _isCountingRows;

- (id) initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) return nil;

    self.statefulState = JMStatefulTableViewControllerStateIdle;
    self.statefulDelegate = self;

    return self;
}
- (void) dealloc {
    self.statefulDelegate = nil;

    [_loadingView release];
    [_emptyView release];
    
    [super dealloc];
}

#pragma mark - Loading Methods

- (void) loadNewer {
    if([self _totalNumberOfRows] == 0) {
        [self _loadFirstPage];
    } else {
        [self _loadFromPullToRefresh];
    }
}

- (void) _loadFirstPage {
    if(self.statefulState == JMStatefulTableViewControllerStateInitialLoading || [self _totalNumberOfRows] > 0) return;

    self.statefulState = JMStatefulTableViewControllerStateInitialLoading;

    [self.tableView reloadData];

    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerWillBeginLoading:)]) {
        [self.statefulDelegate statefulTableViewControllerWillBeginLoading:self];
    }    

    [self.statefulDelegate statefulTableViewControllerWillBeginInitialLoading:self completionBlock:^{
        [self.tableView reloadData]; // We have to call reloadData before we call _totalNumberOfRows otherwise the new count (after loading) won't be accurately reflected.

        if([self _totalNumberOfRows] > 0) {
            self.statefulState = JMStatefulTableViewControllerStateIdle;
        } else {
            self.statefulState = JMStatefulTableViewControllerStateEmpty;
        }

        if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
            [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
        }
    } failure:^(NSError *error) {
        self.statefulState = JMStatefulTableViewControllerErrorWhileInitiallyLoading;

        if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
            [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
        }
    }];
}
- (void) _loadNextPage {
    if(self.statefulState == JMStatefulTableViewControllerStateLoadingNextPage) return;

    if([self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
        self.statefulState = JMStatefulTableViewControllerStateLoadingNextPage;

        if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerWillBeginLoading:)]) {
            [self.statefulDelegate statefulTableViewControllerWillBeginLoading:self];
        }    
        
        [self.statefulDelegate statefulTableViewControllerWillBeginLoadingNextPage:self completionBlock:^{
            [self.tableView reloadData];

            if([self _totalNumberOfRows] > 0) {
                self.statefulState = JMStatefulTableViewControllerStateIdle;
            } else {
                self.statefulState = JMStatefulTableViewControllerStateEmpty;
            }

            if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
                [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
            }
        } failure:^(NSError *error) {
            //TODO What should we do here?
            self.statefulState = JMStatefulTableViewControllerStateIdle;

            if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
                [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
            }
        }];
    }
}

- (void) _loadFromPullToRefresh {
    if(self.statefulState == JMStatefulTableViewControllerStateLoadingFromPullToRefresh) return;

    self.statefulState = JMStatefulTableViewControllerStateLoadingFromPullToRefresh;

    if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerWillBeginLoading:)]) {
        [self.statefulDelegate statefulTableViewControllerWillBeginLoading:self];
    }    

    [self.statefulDelegate statefulTableViewControllerWillBeginLoadingFromPullToRefresh:self completionBlock:^(NSArray *indexPaths) {
        if([indexPaths count] > 0) {
            CGFloat totalHeights = [self _cumulativeHeightForCellsAtIndexPaths:indexPaths];

            //Offset by the height fo the pull to refresh view when it's expanded:
            [self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            [self.tableView reloadData];

            if(self.tableView.contentOffset.y == 0) {
                self.tableView.contentOffset = CGPointMake(0, (self.tableView.contentOffset.y + totalHeights) - 60.0);
            } else {
                self.tableView.contentOffset = CGPointMake(0, (self.tableView.contentOffset.y + totalHeights));
            }
        }

        self.statefulState = JMStatefulTableViewControllerStateIdle;
        [self.tableView.pullToRefreshView stopAnimating];

        if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
            [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
        }
    } failure:^(NSError *error) {
        //TODO: What should we do here?

        self.statefulState = JMStatefulTableViewControllerStateIdle;
        [self.tableView.pullToRefreshView stopAnimating];

        if([self.statefulDelegate respondsToSelector:@selector(statefulTableViewControllerDidFinishLoading:)]) {
            [self.statefulDelegate statefulTableViewControllerDidFinishLoading:self];
        }
    }];
}

#pragma mark - Table View Cells & NSIndexPaths

- (UITableViewCell *) _cellForLoadingCell {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = cell.center;
    [cell addSubview:activityIndicator];
    [activityIndicator release];

    [activityIndicator startAnimating];

    cell.tag = kLoadingCellTag;

    return cell;
}
- (BOOL) _indexRepresentsLastSection:(NSInteger)section {
    NSInteger totalNumberOfSections = [self numberOfSectionsInTableView:self.tableView];
    if(section != (totalNumberOfSections - 1)) return NO; //section is not the last section!

    return YES;
}
- (BOOL) _indexPathRepresentsLastRow:(NSIndexPath *)indexPath {
    NSInteger totalNumberOfSections = [self numberOfSectionsInTableView:self.tableView];
    if(indexPath.section != (totalNumberOfSections - 1)) return NO; //indexPath.section is not the last section!

    NSInteger totalNumberOfRowsInSection = [self tableView:self.tableView numberOfRowsInSection:indexPath.section];
    if(indexPath.row != (totalNumberOfRowsInSection - 1)) return NO; //indexPath.row is not the last row in this section!

    return YES;
}
- (NSInteger) _totalNumberOfRows {
    self.isCountingRows = YES;

    NSInteger numberOfRows = 0;

    NSInteger numberOfSections = [self numberOfSectionsInTableView:self.tableView];
    for(NSInteger i = 0; i < numberOfSections; i++) {
        numberOfRows += [self tableView:self.tableView numberOfRowsInSection:i];
    }

    self.isCountingRows = NO;

    return numberOfRows;
}
- (CGFloat) _cumulativeHeightForCellsAtIndexPaths:(NSArray *)indexPaths {
    if(!indexPaths) return 0.0;

    CGFloat totalHeight = 0.0;

    for(NSIndexPath *indexPath in indexPaths) {
        totalHeight += [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
    }

    return totalHeight;
}

#pragma mark - Setter Overrides

- (void) setStatefulState:(JMStatefulTableViewControllerState)statefulState {
	_statefulState = statefulState;

    switch (_statefulState) {
        case JMStatefulTableViewControllerStateIdle:
            self.tableView.backgroundView = nil;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
            self.tableView.scrollEnabled = YES;
            [self.tableView reloadData];

            break;

        case JMStatefulTableViewControllerStateInitialLoading:
            self.tableView.backgroundView = self.loadingView;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.tableView.scrollEnabled = NO;

            break;

        case JMStatefulTableViewControllerStateEmpty:
            self.tableView.backgroundView = self.emptyView;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.tableView.scrollEnabled = NO;
            [self.tableView reloadData];

        case JMStatefulTableViewControllerStateLoadingNextPage:
            // TODO
            break;

        case JMStatefulTableViewControllerStateLoadingFromPullToRefresh:
            // TODO
            break;
            
        case JMStatefulTableViewControllerErrorWhileInitiallyLoading:
            // TODO
            [self.tableView reloadData];
            break;

        default:
            break;
    }
}

#pragma mark - View Lifecycle

- (void) loadView {
    [super loadView];

    self.loadingView = [[[JMStatefulTableViewLoadingView alloc] initWithFrame:self.tableView.bounds] autorelease];
    self.loadingView.backgroundColor = [UIColor greenColor];

    self.emptyView = [[[JMStatefulTableViewEmptyView alloc] initWithFrame:self.tableView.bounds] autorelease];
    self.emptyView.backgroundColor = [UIColor yellowColor];
}

- (void) viewDidLoad {
    [super viewDidLoad];
}
- (void) viewDidUnload {
    [super viewDidUnload];

    self.loadingView = nil;
    self.emptyView = nil;
}

- (void) viewWillAppear:(BOOL)animated {
    [self _loadFirstPage];

    [self.tableView addPullToRefreshWithActionHandler:^{
        [self _loadFromPullToRefresh];
    }];

    [super viewWillAppear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.statefulDelegate statefulTableViewController:self numberOfSectionsInTableView:tableView];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = [self.statefulDelegate statefulTableViewController:self tableView:tableView numberOfRowsInSection:section];

    if(!self.isCountingRows) {
        if([self _indexRepresentsLastSection:section] && self.statefulState != JMStatefulTableViewControllerStateInitialLoading && [self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
            rows++;
        }
    }

    return rows;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([self _indexPathRepresentsLastRow:indexPath] && [self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
        return [self _cellForLoadingCell];
    } else {
        return [self.statefulDelegate statefulTableViewController:self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    }

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    // Configure the cell...

    cell.textLabel.text = [NSString stringWithFormat:@"Section %d, Row %d", indexPath.section, indexPath.row];

    return cell;
}
- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(cell.tag == kLoadingCellTag && [self.statefulDelegate statefulTableViewControllerShouldBeginLoadingNextPage:self]) {
        [self _loadNextPage];
    }
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - JMStatefulTableViewControllerDelegate

- (void) statefulTableViewControllerWillBeginInitialLoading:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginInitialLoading:completionBlock:failure: is meant to be implementd by it's subclasses!");
}

- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(JMStatefulTableViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginLoadingFromPullToRefresh:completionBlock:failure: is meant to be implementd by it's subclasses!");
}

- (void) statefulTableViewControllerWillBeginLoadingNextPage:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *))failure {
    NSAssert(NO, @"statefulTableViewControllerWillBeginLoadingNextPage:completionBlock:failure: is meant to be implementd by it's subclasses!");    
}
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(JMStatefulTableViewController *)vc {
    NSAssert(NO, @"statefulTableViewControllerShouldBeginLoadingNextPage is meant to be implementd by it's subclasses!");    

    return NO;
}

- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc numberOfSectionsInTableView:(UITableView *)tableView {
    NSAssert(NO, @"statefulTableViewController:numberOfSectionsInTableView: is meant to be implementd by it's subclasses!");
    
    return 0;
}
- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(NO, @"statefulTableViewController:tableView:numberOfRowsInSection: is meant to be implementd by it's subclasses!");

    return 0;
}

- (UITableViewCell *) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(NO, @"statefulTableViewController:tableView:cellForRowAtIndexPath: is meant to be implementd by it's subclasses!");

    return nil;
}

@end