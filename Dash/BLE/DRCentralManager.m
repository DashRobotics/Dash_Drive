//
//  DRCentralManager.m
//  Dash
//
//  Created by Adam Overholtzer on 3/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRCentralManager.h"
#import "DRRobotLeService.h"
#import "DRRobotProperties.h"
#import "NSArray+AnyObject.h"

NSString *const DEMO_ROBOT_UUID = @"FAKE ROBOT FOR DEMO PURPOSES ONLY";

@interface LGPeripheral (IsFake)
- (BOOL)isFake;
@end
@implementation LGPeripheral (IsFake)
- (BOOL)isFake {
    return NO;
}
@end

@interface FakePeripheral : LGPeripheral
@end
@implementation FakePeripheral
- (NSString *)UUIDString {
    return DEMO_ROBOT_UUID;
}
- (BOOL)isFake {
    return YES;
}
@end

@implementation DRCentralManager

static DRCentralManager *_sharedInstance = nil;

+ (DRCentralManager *)sharedInstance
{
    // Thread blocking to be sure for singleton instance
	@synchronized(self) {
		if (!_sharedInstance) {
			_sharedInstance = [DRCentralManager new];
            _sharedInstance.peripheralProperties = [NSMutableDictionary new];
            _sharedInstance.manager.delegate = _sharedInstance;
            
            [[NSNotificationCenter defaultCenter] addObserver:_sharedInstance selector:@selector(peripheralDidDisconnect:) name:kLGPeripheralDidDisconnect object:nil];
		}
	}
	return _sharedInstance;
}

- (LGCentralManager *)manager {
    return [LGCentralManager sharedInstance];
}

- (NSArray *)peripherals {
    if ([DRCentralManager isDemoMode]) {
        FakePeripheral *fakeRobot = [[FakePeripheral alloc] init];
        return [self.manager.peripherals arrayByAddingObject:fakeRobot];
    } else {
        return self.manager.peripherals;
    }
}

+ (BOOL)isDemoMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"demo_mode"];
}

#pragma mark - Scanning

- (void)updatedScannedPeripherals {
    for (LGPeripheral *peripheral in self.peripherals) {
        if (![self.peripheralProperties objectForKey:peripheral.UUIDString]) {
            if (peripheral.isFake) {
                double delayInSeconds = 0.7;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    DRRobotProperties *fakeRobot = [[DRRobotProperties alloc] initWithName:@"DemoBot" color:arc4random_uniform((u_int32_t)ROBOT_COLORS.count)];
                    [self.peripheralProperties setObject:fakeRobot forKey:DEMO_ROBOT_UUID];
                    [self.discoveryDelegate discoveryDidRefresh];
                });
            } else {
                [LGUtils readDataFromCharactUUID:kNotifyCharacteristicUUIDString serviceUUID:kBiscuitServiceUUIDString peripheral:peripheral completion:^(NSData *data, NSError *error) {
                    if (data) {
                        DRRobotProperties *robot = [DRRobotProperties robotPropertiesWithData:data];
                        if (robot) [self.peripheralProperties setObject:robot forKey:peripheral.UUIDString];
                        [self.discoveryDelegate discoveryDidRefresh];
                    }
                    if (!data || error) {
                        NSLog(@"Error getting name/color: %@", error);
                    }
                    [peripheral disconnectWithCompletion:nil];
                }];
            }
        }
    }
    [self.discoveryDelegate discoveryDidRefresh];
}

- (void)startScanning {
	NSArray			*uuidArray	= @[[CBUUID UUIDWithString:kBiscuitServiceUUIDString]];
	NSDictionary	*options	= @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};
    
    [self.manager scanForPeripheralsByInterval:SCAN_INTERVAL services:uuidArray options:options completion:^(NSArray *peripherals) {
        [self.discoveryDelegate stoppedScanning];
    }];
//    [self.discoveryDelegate discoveryDidRefresh];
}

- (void)stopScanning {
    [self.manager stopScanForPeripherals];
    [self.discoveryDelegate stoppedScanning];
}

#pragma mark - Connecting

- (void)connectPeripheral:(LGPeripheral *)peripheral completion:(LGPeripheralConnectionCallback)aCallback{
    if (peripheral.isFake) {
        DRRobotProperties *properties = [self propertiesForPeripheral:peripheral];
        self.connectedService = [[DRRobotLeService alloc] initWithPeripheral:peripheral robotProperties:properties];
        if (aCallback) {
            aCallback(nil);
        }
    } else {
        [peripheral connectWithCompletion:^(NSError *error) {
            if (!error) {
                DRRobotProperties *properties = [self propertiesForPeripheral:peripheral];
                self.connectedService = [[DRRobotLeService alloc] initWithPeripheral:peripheral robotProperties:properties];
            }
            if (aCallback) {
                aCallback(error);
            }
        }];
    }
}

- (void)disconnectPeripheral {
    if (self.connectedService) {
        if (self.connectedService.peripheral.isFake) {
            self.connectedService = nil;
            [self.discoveryDelegate discoveryDidRefresh];
        } else {
            [self.connectedService disconnect];
            [self.connectedService.peripheral performSelector:@selector(disconnectWithCompletion:) withObject:^(NSError *error) {
                [self.discoveryDelegate discoveryDidRefresh];
                NSLog(@"Intentional disconnect complete.");
            } afterDelay:0.1];
            self.connectedService = nil;
        }
    }
}

- (void)peripheralDidDisconnect:(NSNotification *)notification
{
    if (self.connectedService && [self.connectedService.peripheral isEqual:notification.object]) {
        if (!self.connectedService.isManuallyDisconnecting || notification.userInfo[@"error"]) {
            NSString *msg = @"Lost connection with device.";
            if (self.connectedService.robotProperties.hasName) {
                msg = [msg stringByReplacingOccurrencesOfString:@"device" withString:self.connectedService.robotProperties.name];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:msg delegate:self.discoveryDelegate cancelButtonTitle:@"Shucks" otherButtonTitles:nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        }
        [self updateProperties:self.connectedService.robotProperties forPeripheral:self.connectedService.peripheral];
        self.connectedService = nil;
        NSLog(@"Unexpected disconnect of dash service.");
    }
}

#pragma mark - Robot Properties

- (DRRobotProperties *)propertiesForPeripheral:(LGPeripheral *)peripheral {
    return [self.peripheralProperties objectForKey:peripheral.UUIDString];
}

- (void)updateProperties:(DRRobotProperties *)properties forPeripheral:(LGPeripheral *)periperhal {
    if (properties && periperhal) {
        [self.peripheralProperties setObject:properties forKey:periperhal.UUIDString];
    }
}


@end
