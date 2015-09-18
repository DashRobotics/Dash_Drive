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

@interface DRDemoTableViewController ()
@property (weak, nonatomic) DRRobotLeService *bleService;
@end

@implementation DRDemoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bleService = [[DRCentralManager sharedInstance] connectedService];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
