# JMStatefulTableViewController

This is the class I use whenever I need to implement a "stateful" table view in an iOS app. In this context, when I say "stateful" I mean a table view controller that has the following "states":

* Initially loading for the first time since instantiating. (Usually displaying a "loading" view covering the table view entirely).
* An "idle" state, where the user can scroll around and consume content, no special activity happening.
* Loading from a "pull to refresh" gesture.
* Loading the next "page" in a scenario where I need to scroll "infinitely."
* Empty (Usually displaying a nice looking "empty" view covering the table view entirely).
* Error (This is useful when the "initial" load fails or I need to communicate that some other horrible thing has happened).

If you're using `JMStatefulTableViewController` in your application, add it to [the list](https://github.com/jakemarsh/JMStatefulTableViewController/wiki/Applications).

## Example Usage

The demo project hosted in this repo is the first place you should look for how to implement `JMStatefulTableViewController` in your app, but basically you just need to subclass `JMStatefulTableViewController` and implement the required delegate methods on that subclass.

The next section shows an example of how you might implement the required delegate methods.

### First Time Loading

`JMStatefulTableViewController` will call it's `statefulDelegate` with this method, passing it in two blocks, a `success` and `failure` block, when the table view needs to load it's "initial" bit of content. It will also transparently handle changing the state to `JMStatefulTableViewControllerStateInitialLoading` for you. 

You should write or call your code to load your initial set of content inside this method, and then call the correct block for the outcome. If your data loaded successfully, call the `success`, if it failed for some reason call the `failure` block, optionally passing in an `NSError` object, or `nil`.


``` objective-c
- (void) statefulTableViewControllerWillBeginInitialLoading:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *error))failure {
	// Always do any sort of heavy loading work on a background queue:
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        self.catPhotos = [self _loadHilariousCatPhotosFromTheInternet];
                                                    
		// Always call success() on the main queue:
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });
}
```

### Loading From Pull To Refresh

`JMStatefulTableViewController` will call it's `statefulDelegate` with this method, passing it in two blocks, a `success` and `failure` block when the user finishes a "pull to refresh" gesture. Note that the `success` block in this case is asking for an array of `NSIndexPath` objects.

I've implemented it this way so I can easily achieve what I call "proper" pull to refresh style loading. In "proper" pull to refresh loading, the existing content stays in place and the new content appears above it, without offsetting the table view at all. This is how Loren Brichter (original inventor of the concept) [Loren Brichter](http://twitter.com/lorenb) originally invented and intended it to work. In my opinion it also makes more logical sense. However, if you'd like, you can simple pass `nil` in for the array of `NSIndexPaths` or an empty `NSArray` object, and `JMStatefulTableViewController` will degrade gracefully, replacing the content in your tableview with the latest content. 

You should write or call your code to load any newer content than the current first item (or optionally just reload everything, like many apps do these days), and then call the correct block for the outcome. If your data loaded successfully, call the `success` block, if it failed for some reason call the `failure` block, optionally passing in an `NSError` object, or `nil`.

``` objective-c
- (void) statefulTableViewControllerWillBeginLoadingFromPullToRefresh:(JMStatefulTableViewController *)vc completionBlock:(void (^)(NSArray *indexPathsToInsert))success failure:(void (^)(NSError *error))failure {
	// Always do any sort of heavy loading work on a background queue:
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
		// Grab what is currently our first photo
		CatPhoto *photo = [self.catPhotos objectAtIndex:0];
		
		// Load any newer photos that might have been added on our server
        NSArray *catPhotos = [self _loadHilariousCatPhotosFromTheInternetNewerThanPhoto:photo];

		// Prepend our self.catPhotos array with these new photos we loaded
        self.catPhotos = [catPhotos arrayByAddingObjectsFromArray:self.catPhotos];

		// Put together an array of NSIndexPath objects representing
		// what the index paths will be of the new rows that will be created
        NSMutableArray *a = [NSMutableArray array];

        for(NSInteger i = 0; i < loadedBeerStrings.count; i++) {
            [a addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }

		// Always call success() on the main queue:
        dispatch_async(dispatch_get_main_queue(), ^{
			// If we didn't want to achieve "proper" pull to refresh behavior, we could just pass `nil` in here:
            success([NSArray arrayWithArray:a]);
        });
    });
}
```

### Loading The Next "Page"

`JMStatefulTableViewController` will call it's `statefulDelegate` with this method, passing it in two blocks, a `success` and `failure` block, when the users scrolls to the bottom of your table view.

You should write or call your code to load the next set of content, and then call the correct block for the outcome. If your data loaded successfully, call the `success` block, if it failed for some reason call the `failure` block, optionally passing in an `NSError` object, or `nil`.

``` objective-c                                                                 
- (void) statefulTableViewControllerWillBeginLoadingNextPage:(JMStatefulTableViewController *)vc completionBlock:(void (^)())success failure:(void (^)(NSError *))failure {
	// Always do any sort of heavy loading work on a background queue:
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
		// Grab what is currently our last photo
		CatPhoto *photo = [self.catPhotos lastObject];
		
		// Load any older cat photos from our server
        NSArray *catPhotos = [self _loadHilariousCatPhotosFromTheInternetNewerThanPhoto:photo];

		// Append the new photos we've loaded to the end of your self.catPhotos array
		self.catPhotos = [self.catPhotos arrayByAddingObjectsFromArray:catPhotos];

		// Always call success() on the main queue:
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    });    
}   
```

### Loading The Next "Page"

`JMStatefulTableViewController` will call it's `statefulDelegate` with this method to determine if it can load any more content.

You should return a value indicating whether or not any more content exists to be loaded. This will control whether or not the user is shown a "Loading more" visual state.

``` objective-c
- (BOOL) statefulTableViewControllerShouldBeginLoadingNextPage:(JMStatefulTableViewController *)vc {
    return [self _areThereAnyMoreHilariousCatPhotosOnTheServer];
}
```

## Pull To Refresh Customization

`JMStatefulTableViewController` uses [@samvermette](https://github.com/samvermette)'s excellent [`SVPullToRefresh`](https://github.com/samvermette/SVPullToRefresh) library to accomplish both pull to refresh and infinite scrolling. It is very customizable, [you can read all about how in `SVPullToRefresh`'s documentation](https://github.com/samvermette/SVPullToRefresh#readme).

## Empty, Loading and Error Views

The demo app in this repo uses the built-in implementations of these views. Right now, they are simply full width and height solid color views, to give you something to look at when building your app.

You can subclass `JMStatefulTableViewLoadingView`, `JMStatefulTableViewEmptyView` and `JMStatefulTableViewErrorView` respectively. Currently, they do not offer any special functionality or look and feel, but in the future they will emulate a "system" look and feel for these states. Feel free to take them or leave them.

`JMStatefulTableViewController` has three properties:

``` objective-c
@property (strong, nonatomic) UIView *emptyView;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UIView *errorView;
```

You can set these to any `UIView` you'd like, to indicate any of these states. Like I said, right now, by default, they're not anything useful, just solid colored views.

## Adding To Your Project

### With CocoaPods

If you are using [CocoaPods](http://cocoapods.org) than just add next line to your `Podfile`:

``` ruby
pod 'JMStatefulTableViewController'
```

Now run `pod install` to install the dependency.

### Without CocoaPods

[Download](https://github.com/jakemarsh/JMStatefulTableViewController/zipball/master) the source files or add it as a [git submodule](http://schacon.github.com/git/user-manual.html#submodules). Here's how to add it as a submodule:

    $ cd YourProject
    $ git submodule add https://github.com/jakemarsh/JMStatefulTableViewController.git Vendor/JMStatefulTableViewController

Add all of the Objective-C files to your project.

`JMStatefulTableViewController` uses [Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html). If your project doesn't use ARC, you will need to set the `-fobjc-arc` compiler flag on all of the SSPullToRefresh source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. In the "Compiler Flags" column, set `-fobjc-arc` for each of the `JMStatefulTableViewController` source files.