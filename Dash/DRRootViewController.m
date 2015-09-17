//
//  DRRootViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 3/30/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRRootViewController.h"
#import "DRRobotLeService.h"
#import "DRRobotProperties.h"
#import "DRDeviceCell.h"
#import "DRTabBarController.h"
#import "DRWebViewController.h"
#import "CAShapeLayer+Progress.h"
//#import "Flurry.h"

NSNumber *currentTime;
NSTimeInterval TimeInterval;

@interface DRRootViewController () {
    BOOL _shouldShowResults;
}
@property (weak, nonatomic) DRCentralManager *bleManager;
@property (strong, nonatomic) NSTimer *scanTimer;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *myNavigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *myNavigationItem;
@property (weak, nonatomic) CAShapeLayer *scanProgressLayer;
- (IBAction)didTapAboutButton:(id)sender;
- (IBAction)didTapBuildButton:(id)sender;
- (IBAction)didTapRefreshButton:(id)sender;
- (IBAction)didTapStopButton:(id)sender;
@end

@implementation DRRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bleManager = [DRCentralManager sharedInstance];
    self.bleManager.discoveryDelegate = self;
    
    if (IS_IPAD) {
        [self.myNavigationBar setBackgroundImage:[UIImage imageNamed:@"blank"] forBarMetrics:UIBarMetricsDefault];
        
        UIView *contentView = [self.view viewWithTag:666];
        contentView.transform = CGAffineTransformMakeTranslation(320, 0);
        [UIView animateWithDuration:0.6 delay:0.3 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            contentView.transform = CGAffineTransformIdentity;
        } completion:nil];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panContentView:)];
        panGesture.maximumNumberOfTouches = 1;
        [contentView addGestureRecognizer:panGesture];
    } else {
        self.myNavigationItem = self.navigationItem;
        self.myNavigationBar = self.navigationController.navigationBar;
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    // create animated progress bar
    CAShapeLayer *layer = [CAShapeLayer layer];
    [layer configureForView:self.myNavigationBar];
    [self.myNavigationBar.layer addSublayer:layer];
    self.scanProgressLayer = layer;
}

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
    if (IS_IPAD) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
        [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];
    }
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self appDidBecomeActive];
}

- (void)appDidBecomeActive
{
    [self startScanning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.scanProgressLayer removeAllAnimations];
    if (IS_IPAD) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self appWillResignActive];
}

- (void)appWillResignActive
{
    _shouldShowResults = NO;
    [self.scanProgressLayer removeAllAnimations];
    [[DRCentralManager sharedInstance] stopScanning];
    [self.scanTimer invalidate];
}


#pragma mark - IBActions

- (void)didTapRefreshButton:(id)sender
{
    [self.bleManager.peripheralProperties removeAllObjects];
    [self startScanning];
}

- (void)startScanning
{
    _shouldShowResults = YES;
    
    if (self.bleManager.manager.isCentralReady) {
        [self.scanProgressLayer animateForDuration:SCAN_INTERVAL];
        [self.bleManager startScanning];
        
        [self.scanTimer invalidate];
        self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:RESCAN_INTERVAL target:self selector:@selector(startScanning) userInfo:nil repeats:NO];
        [self.myNavigationItem setRightBarButtonItem:self.stopButton animated:NO];
    } else {
        [self.bleManager startScanning];
//        [self discoveryDidRefresh];
    }
}

- (void)didTapStopButton:(id)sender
{
    [self.bleManager stopScanning];
    [self.scanProgressLayer removeAllAnimations];
}

- (IBAction)didTapAboutButton:(id)sender 
{    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    DRWebViewController *dvc = [DRWebViewController webViewWithUrl:[NSURL fileURLWithPath:path]];
    dvc.title = [sender currentTitle];
    [self.navigationController pushViewController:dvc animated:YES];
}

- (IBAction)didTapBuildButton:(id)sender 
{
    
    DRWebViewController *dvc = [DRWebViewController webViewWithUrl:[[NSBundle mainBundle] URLForResource:@"instructions" withExtension:@"pdf"]];
    dvc.title = [sender currentTitle];
    [self.navigationController pushViewController:dvc animated:YES];

    NSLog(@"TimersStarted");
}

#pragma mark - DRDiscoveryDelegate

- (void)discoveryDidRefresh
{
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
}

- (void)stoppedScanning
{
    [self.myNavigationItem setRightBarButtonItem:self.refreshButton animated:YES];
    if (_shouldShowResults && self.bleManager.peripherals.count && !self.bleManager.manager.scanning
        && [self.collectionView numberOfItemsInSection:0] == self.bleManager.peripherals.count+1) {
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    } else {
        [self discoveryDidRefresh];
    }
}

- (void)discoveryStatePoweredOff
{
    [self.collectionView reloadData];
    
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to connect to Dash.";
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!_shouldShowResults) {
        return 0;
    } else {
        NSUInteger perifCount = self.bleManager.peripherals.count;
        if (self.bleManager.manager.scanning) perifCount += 1;
        return MAX(1, perifCount);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_shouldShowResults) {
        NSInteger index = self.bleManager.manager.scanning ? indexPath.row - 1 : indexPath.row;
        if (index >= 0 && index < self.bleManager.peripherals.count) {
            static NSString *CellIdentifier = @"DRDeviceCell";
            DRDeviceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            
            LGPeripheral *peripheral = self.bleManager.peripherals[index];
            DRRobotProperties *robot = [self.bleManager propertiesForPeripheral:peripheral];
            cell.textLabel.text = robot.hasName ? robot.name : (peripheral.name.length ? peripheral.name : @"Robot");
            cell.detailTextLabel.text = peripheral.UUIDString;
            if (robot) {
                cell.imageView.backgroundColor = robot.color;
                cell.imageView.tintColor = [UIColor whiteColor];
                cell.imageView.layer.borderColor = [UIColor clearColor].CGColor;
            } else {
                cell.imageView.tintColor = [UIColor colorWithRed:0.663 green:0.663 blue:0.663 alpha:1.000];
                cell.imageView.layer.borderColor = cell.imageView.tintColor.CGColor;
                cell.imageView.backgroundColor = [UIColor whiteColor];
            }
            return cell;
        } else {
            static NSString *CellIdentifier = @"explanation";
            DRDeviceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            if (!self.bleManager.manager.isCentralReady) {
                cell.textLabel.text = self.bleManager.manager.centralNotReadyReason.uppercaseString;
            } else {
                if (self.bleManager.manager.scanning) {
                    cell.textLabel.text = @"SCANNING FOR ROBOTS…";
                } else {
                    if (self.bleManager.peripherals.count == 0) {
                        cell.textLabel.text = @"NO ROBOTS FOUND";
                    } else {
                        cell.textLabel.text = @"UNKNOWN ERROR";
                    }
                }
            }
            return cell;
        }
    } else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"blank" forIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
    NSInteger index = self.bleManager.manager.scanning ? indexPath.row - 1 : indexPath.row;
    CGFloat width = CGRectGetWidth(collectionView.bounds) - flowLayout.sectionInset.left - flowLayout.sectionInset.right;
    if (index < 0 || !self.bleManager.peripherals.count) {
        return CGSizeMake(width, 16); // explanation row
    } else {
        return CGSizeMake(width, flowLayout.itemSize.height);
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = self.bleManager.manager.scanning ? indexPath.row - 1 : indexPath.row;
    return (_shouldShowResults && index >=0 && index < self.bleManager.peripherals.count);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = self.bleManager.manager.scanning ? indexPath.row - 1 : indexPath.row;
    if (index >= 0 && index < self.bleManager.peripherals.count) {
        LGPeripheral *peripheral = self.bleManager.peripherals[index];
        [[DRCentralManager sharedInstance] connectPeripheral:peripheral completion:^(NSError *error) {
            if (!error && self.bleManager.connectedService) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                DRTabBarController *vc = (DRTabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"DriveController"];
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Connection Failed" message:@"Unable to connect to device." delegate:self cancelButtonTitle:@"Shucks" otherButtonTitles:nil] show];
            }
        }];
    }
}

#pragma mark - iPad specific

- (void)panContentView:(UIPanGestureRecognizer *)panGesture
{
    UIView *contentView = [self.view viewWithTag:666];
    CGFloat xTranslation = [panGesture translationInView:contentView.superview].x;
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged: {
            if (xTranslation < 0) xTranslation /= 20;
            contentView.layer.transform = CATransform3DMakeTranslation(xTranslation, 0, 0);
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:{
            NSTimeInterval animationDuration = xTranslation < 0 ? 0.2 : 0.5;
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.66 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                contentView.layer.transform = CATransform3DIdentity;
            } completion:nil];
            
            break;
        }
        default:
            break;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            [self.view viewWithTag:12].alpha = 1;
            [self.view viewWithTag:21].alpha = 0;
        } else {
            [self.view viewWithTag:12].alpha = 0;
            [self.view viewWithTag:21].alpha = 1;
        }
    }];
}

@end
