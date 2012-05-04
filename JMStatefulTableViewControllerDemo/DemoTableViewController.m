//
//  DemoTableViewController.m
//  JMStatefulTableViewControllerDemo
//
//  Created by Jake Marsh on 5/3/12.
//  Copyright (c) 2012 Rubber Duck Software. All rights reserved.
//

#import "DemoTableViewController.h"

@interface DemoTableViewController ()

@property (nonatomic, retain) NSArray *beers;
- (NSArray *) _twentyRandomBeerStrings;

@end

@implementation DemoTableViewController

@synthesize beers = _beers;

- (id) initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) return nil;

    self.beers = [NSArray array];

    return self;
}

- (NSArray *) _twentyRandomBeerStrings {
    return [NSArray arrayWithObjects:@"Budweiser", @"Iron City", @"Amstel Light", @"Red Stripe", @"Smithwicks", @"Foster’s", @"Victory", @"Corona", @"Ommegang", @"Chimay", @"Stella Artois", @"Paulaner", @"Newcastle", @"Samuel Adams", @"Rogue", @"Sam Smith’s", @"Yuengling", @"Guinness", @"Sierra Nevada", @"Westvleteren", nil];
}

#pragma mark - View Lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) viewDidUnload {
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - JMStatefulTableViewControllerDelegate

- (void) statefulTableViewControllerWillBeginInitialLoading:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);

        self.beers = [self _twentyRandomBeerStrings];

        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });
}

- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(JMStatefulTableViewController *)vc completionBlock:(void (^)(NSArray *indexPaths))success failure:(void (^)(NSError *error))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);

        NSArray *loadedBeerStrings = [self _twentyRandomBeerStrings];

        self.beers = [loadedBeerStrings arrayByAddingObjectsFromArray:self.beers];

        NSMutableArray *a = [NSMutableArray array];

        for(NSInteger i = 0; i < loadedBeerStrings.count; i++) {
            [a addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            success([NSArray arrayWithArray:a]);
        });
    });
}

- (void) statefulTableViewControllerWillBeginLoadingNextPage:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *))failure {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        sleep(2);

        self.beers = [self.beers arrayByAddingObjectsFromArray:[self _twentyRandomBeerStrings]];

        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });    
}
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(JMStatefulTableViewController *)vc {
    return self.beers.count <= 100;
}

- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.beers.count;
}

- (UITableViewCell *) statefulTableViewController:(JMStatefulTableViewController *)vc tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BeerCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSString *beer = [self.beers objectAtIndex:indexPath.row];

    cell.textLabel.text = beer;

    return cell;
}

@end