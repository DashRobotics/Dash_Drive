//
//  DRControlsViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 3/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRControlsViewController.h"
#import "DRTabBarController.h"
#import "DRCentralManager.h"
#import "DRRobotLeService.h"

@interface DRControlsViewController ()

@end

@implementation DRControlsViewController

- (id) init {
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bleService = [[DRCentralManager sharedInstance] connectedService];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.bleService.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    if (self.bleService.delegate == self) {
        self.bleService.delegate = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Styling

- (void) addTopBorderToView:(UIView *)view
{
    CGFloat borderWidth = IS_RETINA ? 0.5 : 1.0;
    CALayer *topBorder = [CALayer layer];
    topBorder.backgroundColor = DR_LITE_GRAY.CGColor;//[DR_DARK_GRAY colorWithAlphaComponent:0.666].CGColor;
    topBorder.frame = CGRectMake(-1000, 0, 2000, borderWidth);
    [view.layer addSublayer:topBorder];
}

- (void)addBottomBorderToView:(UIView *)view
{
    CGFloat borderWidth = IS_RETINA ? 0.5 : 1.0;
    [self addBottomBorderWithColor:DR_LITE_GRAY width:borderWidth toView:view];
}

- (void) addBottomBorderWithColor:(UIColor *)color width:(CGFloat)width toView:(UIView *)view;
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.backgroundColor = color.CGColor;
    bottomBorder.frame = CGRectMake(-1000, CGRectGetHeight(view.bounds)-width, 2000, width);
    [view.layer addSublayer:bottomBorder];
}

- (void)addBordersToView:(UIView *)view
{
    CGFloat borderWidth = IS_RETINA ? 0.5 : 1.0;
    view.layer.borderColor = DR_LITE_GRAY.CGColor;
    view.layer.borderWidth = borderWidth;
}

#pragma mark - DRRobotLeServiceDelegate

- (void)receivedNotifyWithData:(NSData *)data
{
}

- (void)receivedNotifyWithSignals:(DRSignalPacket *)signals
{
}

- (void)receivedNotifyWithProperties:(DRRobotProperties *)properties
{
}

@end
