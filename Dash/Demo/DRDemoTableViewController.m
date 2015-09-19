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
    DRDemoTableRowRedFlashes = 0,
    DRDemoTableRowGreenFlashes,
    DRDemoTableRowColorfulFlashes,
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

- (void)flashColors:(NSArray *)colors onDuration:(NSTimeInterval)onDuration offDuration:(NSTimeInterval)offDuration {
    NSTimeInterval delay = 0.0;
    for (NSUInteger i = 0; i < colors.count*2; i++) {
        UIColor *color = (i % 2)? kDREyeColorOff : [colors objectAtIndex:i/2.0];
        [self.bleService performSelector:@selector(setEyeColor:) withObject:color afterDelay:delay];
        delay += (i % 2)? offDuration : onDuration;
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section && indexPath.row < DRDemoTableRowCount) {
        switch (indexPath.row) {
            case DRDemoTableRowRedFlashes:
            {
                [self flashColors:@[
                                    [UIColor redColor],
                                    [UIColor redColor],
                                    [UIColor redColor],
                                    [UIColor redColor],
                                    [UIColor redColor],
                                    ] onDuration:0.065 offDuration:0.035];
                break;
            }
            case DRDemoTableRowGreenFlashes:
            {
                [self flashColors:@[
                                   [UIColor greenColor],
                                   [UIColor greenColor],
                                   ] onDuration:0.085 offDuration:0.035];
                break;
            }
            case DRDemoTableRowColorfulFlashes:
            {
                [self flashColors:@[
                                    [UIColor redColor],
                                    [UIColor greenColor],
                                    [UIColor blueColor],
                                    [UIColor whiteColor],
                                    ] onDuration:0.25 offDuration:0.01];
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
