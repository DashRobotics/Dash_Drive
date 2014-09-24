//
//  DRSignalPacket.m
//  Dash
//
//  Created by Adam Overholtzer on 4/15/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRSignalPacket.h"

@implementation DRSignalPacket

+ (instancetype)signalPacketWithData:(NSData *)data
{
    // [type - "2" - 1] [ mode - 0-10 - 1] [ yaw - 0-1024 - 2] [ambient light - 0-1024 - 2] [proxLeft - 0-1024 - 2] [proxRight - 0-1024 - 2] [mtrA1 - 0-255 - 1] [mtrA2 - 0-255 - 1] [mtrB1 - 0-255 - 1] [mtrB2 - 0-255 - 1]

    if (data.length >= PACKET_SIZE) {
        DRSignalPacket *signals = [DRSignalPacket new];
        
        char mode;
        uint16_t yaw, light, proxLeft, proxRight;
        uint8_t mtrA1, mtrA2, mtrB1, mtrB2;
        NSUInteger index = 1;
        
        read(data, mode, index);
        read(data, yaw, index);
        read(data, light, index);
        read(data, proxLeft, index);
        read(data, proxRight, index);
        read(data, mtrA1, index);
        read(data, mtrA2, index);
        read(data, mtrB1, index);
        read(data, mtrB2, index);

        signals.mode = mode;
        signals.yaw = NSSwapShort(yaw);
        signals.ambientLight = NSSwapShort(light);
        signals.proximityLeft = NSSwapShort(proxLeft);
        signals.proximityRight = NSSwapShort(proxRight);
        signals.leftMotor = mtrA1 - mtrA2;
        signals.rightMotor = mtrB1 - mtrB2;
        
        return signals;
    } else {
        return nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"yaw: %lu\nlight: %lu\nproximity: %lu / %lu\nmotor: %ld / %ld",
            /*self.mode,*/ (unsigned long)self.yaw, (unsigned long)self.ambientLight,
            (unsigned long)self.proximityLeft, (unsigned long)self.proximityRight,
            (long)self.leftMotor, (long)self.rightMotor];
}

@end
