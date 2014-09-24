//
//  DRRobotProperties.h
//  Dash
//
//  Created by Adam Overholtzer on 4/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DRRobotLeService.h"

// Dark Blue, Red, Holiday Green, Lemon Yellow, Black, Orange
#define ROBOT_COLORS @[ [UIColor lightGrayColor], \
                        [UIColor colorWithRed:0.191 green:0.287 blue:0.611 alpha:1.000], \
                        [UIColor colorWithRed:0.905 green:0.150 blue:0.119 alpha:1.000], \
                        [UIColor colorWithRed:0.149 green:0.591 blue:0.279 alpha:1.000], \
                        [UIColor colorWithRed:0.929 green:0.799 blue:0.145 alpha:1.000], \
                        [UIColor colorWithRed:0.136 green:0.147 blue:0.157 alpha:1.000], \
                        [UIColor colorWithRed:0.952 green:0.501 blue:0.115 alpha:1.000], \
]

typedef NS_ENUM(NSUInteger, DRRobotColorNames) {
    DRColorUndefined = 0,
    DRBlue,
    DRRedRobot,
    DRGreenRobot,
    DRYellowRobot,
    DRBlackRobot,
    DROrangeRobot,
};

@interface DRRobotProperties : NSObject

@property (strong, nonatomic) NSString *name;
@property NSUInteger robotType, codeVersion;
@property DRRobotColorNames colorIndex;

- (BOOL)hasName;

- (id)initWithName:(NSString *)name color:(NSUInteger)color;

+ (instancetype)robotPropertiesWithData:(NSData *)data;

- (UIColor *)color;

@end
