//
//  DRAppDelegate.m
//  Dash
//
//  Created by Adam Overholtzer on 3/1/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRAppDelegate.h"
#import "DRCentralManager.h"
#import "DRRobotLeService.h"
#import "DRWebViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation DRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[[Crashlytics class]]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"Gyro-pref" : @YES }];

//    UIStoryboard *storyboard = IS_IPAD ? [UIStoryboard storyboardWithName:@"Main~iPad" bundle:nil]
//                                        : [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    self.window.rootViewController = [storyboard instantiateInitialViewController];
//    [self.window makeKeyAndVisible];

    [self configureStyling];
    
    return YES;
}

- (void)configureStyling
{
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium" size:19],
                                                           }];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:17],
                                                           } forState:UIControlStateNormal];
    
    NSDictionary *segmentedControlTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14],
                                                     NSForegroundColorAttributeName: [UIColor blackColor] };
    [[UISegmentedControl appearance] setTitleTextAttributes:segmentedControlTextAttributes forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:segmentedControlTextAttributes forState:UIControlStateSelected];
    [[UISegmentedControl appearance] setTintColor:DR_LITE_GRAY];
    [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0, IS_RETINA ? 1 : 0) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];
    
    self.window.tintColor = [UIColor blackColor];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[[DRCentralManager sharedInstance] connectedService] reset];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[DRCentralManager sharedInstance] disconnectPeripheral];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *rootNavigationController = (UINavigationController *)self.window.rootViewController;
        if (![rootNavigationController.visibleViewController isKindOfClass:[DRWebViewController class]]) {
            [rootNavigationController popToRootViewControllerAnimated:NO];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[DRCentralManager sharedInstance] disconnectPeripheral];
    [[DRCentralManager sharedInstance] stopScanning];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (IS_IPAD) {
        return UIInterfaceOrientationMaskAll;
    } else {
        NSString *className = nil;
        if (window.rootViewController.presentedViewController) {
            className = NSStringFromClass(window.rootViewController.presentedViewController.class);
        }
        if ([className isEqualToString:@"MPFullscreenWindow"] || [className isEqualToString:@"MPInlineVideoFullscreenViewController"]) {
            return UIInterfaceOrientationMaskAll;
        } else {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
}

@end
