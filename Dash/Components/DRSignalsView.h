//
//  DRSignalsViewController.h
//  Dash
//
//  Created by Adam Overholtzer on 5/5/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+NibLoading.h"

@class DRSignalPacket, DRRobotProperties;

@interface DRSignalsView : NibLoadedView

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *robotImageView;

@property (weak, nonatomic) IBOutlet UILabel *yawRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorRightLabel;
@property (weak, nonatomic) IBOutlet UILabel *ambientLightLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityRightLabel;

- (void) updateWithSignals:(DRSignalPacket *)signals;
- (void) updateWithProperties:(DRRobotProperties *)properties;

@end
