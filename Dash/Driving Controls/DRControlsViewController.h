//
//  DRControlsViewController.h
//  Dash
//
//  Created by Adam Overholtzer on 3/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DRRobotLeService.h"

@interface DRControlsViewController : UIViewController <DRRobotLeServiceDelegate>

@property (weak, nonatomic) DRRobotLeService *bleService;

- (void)addBordersToView:(UIView *)view;
- (void)addTopBorderToView:(UIView *)view;
- (void)addBottomBorderToView:(UIView *)view;

- (void)addBottomBorderWithColor:(UIColor *)color width:(CGFloat)width toView:(UIView *)view;

@end
