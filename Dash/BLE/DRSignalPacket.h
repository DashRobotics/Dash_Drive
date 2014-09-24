//
//  DRSignalPacket.h
//  Dash
//
//  Created by Adam Overholtzer on 4/15/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRRobotLeService.h"

@interface DRSignalPacket : NSObject

@property (nonatomic) DRCommandTypes mode;

@property NSUInteger yaw, ambientLight, proximityLeft, proximityRight;
@property NSInteger leftMotor, rightMotor;

+ (instancetype)signalPacketWithData:(NSData *)data;

@end
