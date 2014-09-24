//
//  DRSignalsViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 5/5/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRSignalsView.h"
#import "DRSignalPacket.h"
#import "DRRobotProperties.h"

@interface DRSignalsView ()
@end

@implementation DRSignalsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.nameLabel.text = @"Robot";
    self.robotImageView.image = [self.robotImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.yawRateLabel.text = @"0";
    self.motorLeftLabel.text = @"0";
    self.motorRightLabel.text = @"0";
    self.ambientLightLabel.text = @"0";
    self.proximityLeftLabel.text = @"0";
    self.proximityRightLabel.text = @"0";
}

- (void)updateWithProperties:(DRRobotProperties *)properties
{
    if (properties.hasName) {
        self.nameLabel.text = properties.name;
    } else {
        self.nameLabel.text = @"Robot";
    }
    self.robotImageView.tintColor = properties.color;
}

- (void)updateWithSignals:(DRSignalPacket *)signals
{
    self.yawRateLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)signals.yaw];
//    self.yawRateLabel.text = [NSString stringWithFormat:@"%.0f", signals.yaw - 512.0 + 51.0];
    self.motorLeftLabel.text = [NSString stringWithFormat:@"%.0f", round(-signals.leftMotor / 255.0 * 100.0)];
    self.motorRightLabel.text = [NSString stringWithFormat:@"%.0f", round(-signals.rightMotor / 255.0 * 100.0)];
//    self.motorLeftLabel.text = [NSString stringWithFormat:@"%ld", (long)signals.leftMotor];
//    self.motorRightLabel.text = [NSString stringWithFormat:@"%ld", (long)signals.rightMotor];
    self.ambientLightLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)signals.ambientLight];
    self.proximityLeftLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)signals.proximityLeft];
    self.proximityRightLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)signals.proximityRight];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(320, 135);
}

@end
