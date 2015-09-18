//
//  DRDemoTableViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 9/16/15.
//  Copyright (c) 2015 Dash Robotics. All rights reserved.
//

#import "DRDemoTableViewController.h"
#import "DRCentralManager.h"
#import "DRRobotLeService.h"

typedef NS_ENUM(NSInteger, DRDemoTableRows) {
    DRDemoTableRowLaserHit = 0,
    DRDemoTableRowRedEyeRun,
    DRDemoTableRowCount
};

@interface DRDemoTableViewController ()
@property (weak, nonatomic) DRRobotLeService *bleService;
@end

@implementation DRDemoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bleService = [[DRCentralManager sharedInstance] connectedService];
}

#pragma mark - IBActions

- (IBAction)didLightButtonTouchDown:(UIButton *)sender {
    self.bleService.eyeColor = sender.backgroundColor;
}

- (IBAction)didLightButtonRelease:(UIButton *)sender {
//    self.bleService.eyeColor = kDREyeColorOff;
    [self.bleService performSelector:@selector(setEyeColor:) withObject:kDREyeColorOff afterDelay:0.075];
}

- (void)driveForwardAtSpeed:(NSNumber *)speed {
    [self.bleService sendLeftMotor:speed.doubleValue rightMotor:speed.doubleValue];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section && indexPath.row < DRDemoTableRowCount) {
        switch (indexPath.row) {
            case DRDemoTableRowLaserHit:
            {
                for (NSUInteger i = 0; i < 8; i++) {
                    UIColor *color = (i % 2)? kDREyeColorOff : [UIColor redColor];
                    [self.bleService performSelector:@selector(setEyeColor:) withObject:color afterDelay:0.075*i];
                }
                break;
            }
            case DRDemoTableRowRedEyeRun:
            {
                [self.bleService performSelector:@selector(setEyeColor:) withObject:[UIColor redColor] afterDelay:0];
                [self performSelector:@selector(driveForwardAtSpeed:) withObject:@(100) afterDelay:0];
                [self.bleService performSelector:@selector(reset) withObject:nil afterDelay:3];
                [self.bleService performSelector:@selector(setEyeColor:) withObject:kDREyeColorOff afterDelay:3];
                break;
            }
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
