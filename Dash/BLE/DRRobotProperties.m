//
//  DRRobotProperties.m
//  Dash
//
//  Created by Adam Overholtzer on 4/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRRobotProperties.h"

@implementation DRRobotProperties

- (BOOL)hasName {
    return self.name.length > 0;
}

- (id)initWithName:(NSString *)name color:(NSUInteger)color
{
    self = [super init];
    if (self) {
        [self setName:name];
        _colorIndex = color;
    }
    return self;
}

+ (instancetype)robotPropertiesWithData:(NSData *)data
{
    // [type "1" - 1]  [robot Type - 0-255 - 1] [robot color - 0-255 - 1] [code version - 0-255 - 1] [name - string - 10, terminated with a null character]
    
    if (data.length == PACKET_SIZE) {
        DRRobotProperties *properties = [DRRobotProperties new];
        
        char msgType;
        uint8_t robotType, robotColor, codeVersion;
        NSData *name;
        NSUInteger index = 0;
        
        read(data, msgType, index);
        read(data, robotType, index);
        read(data, robotColor, index);
        read(data, codeVersion, index);
        
        if (msgType == DRMessageTypeName) {
            name = [data subdataWithRange:NSMakeRange(index, data.length-index)];
            properties.name = [NSString stringWithUTF8String:name.bytes];
            
            properties.colorIndex = robotColor;
            properties.codeVersion = codeVersion;
            properties.robotType = robotType;
            
            return properties;
        } else {
            NSLog(@"DRRobotProperties: wrong msgType (%c)", msgType);
            return nil;
        }
    } else {
        return nil;
    }

}

- (void)setName:(NSString *)name
{
    if (name.length) {
        while ([name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > MAX_NAME_LENGTH) {
            name = [name substringToIndex:name.length-1];
        }
    }
    _name = name;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"DRRobotProperties : '%@' %lu", self.name, (unsigned long)self.colorIndex];
}

- (UIColor *)color {
    if (self.colorIndex < ROBOT_COLORS.count) {
        return ROBOT_COLORS[self.colorIndex];
    } else {
        return ROBOT_COLORS[DRColorUndefined];
    }
}

@end
