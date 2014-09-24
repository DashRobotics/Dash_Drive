/*

 File: LeTemperatureAlarmService.m
 
 Abstract: Temperature Alarm Service Code - Connect to a peripheral 
 get notified when the temperature changes and goes past settable
 maximum and minimum temperatures.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */



#import "DRRobotLeService.h"
#import "LeDiscovery.h"
#import "DRSignalPacket.h"
#import "DRRobotProperties.h"

NSString *const kBiscuitServiceUUIDString = @"713D0000-503E-4C75-BA94-3148F18D941E";
NSString *const kRead1CharacteristicUUIDString = @"713D0001-503E-4C75-BA94-3148F18D941E";
NSString *const kNotifyCharacteristicUUIDString = @"713D0002-503E-4C75-BA94-3148F18D941E";
NSString *const kWriteWithoutResponseCharacteristicUUIDString = @"713D0003-503E-4C75-BA94-3148F18D941E";

@interface DRRobotLeService() {
    UIColor *_eyeColor;
}
@property (readwrite, strong, nonatomic) LGPeripheral *peripheral;
@property (strong, nonatomic) LGService *robotService;
@property (strong, nonatomic) LGCharacteristic *writeWoResponseCharacteristic, *notifyCharacteristic;
@end

@implementation DRRobotLeService

#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
- (id)initWithPeripheral:(LGPeripheral *)peripheral robotProperties:(DRRobotProperties *)properties
{
    self = [super init];
    if (self) {
        _robotProperties = properties;
        _peripheral = peripheral;
        [self discover]; // lol
    }
    return self;
}

- (void)discover
{
    CBUUID *serviceUuid = [CBUUID UUIDWithString:kBiscuitServiceUUIDString];
    
    __weak typeof(self) weakSelf = self;

    [self.peripheral discoverServices:@[serviceUuid] completion:^(NSArray *services, NSError *error) {
        for (LGService *service in services) {
            if ([service.UUIDString isEqualToString:kBiscuitServiceUUIDString]) {
                weakSelf.robotService = service;
                [weakSelf.robotService discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                    [weakSelf processCharacteristics:characteristics];
                }];
                break;
            }
        }
    }];
}

- (void)processCharacteristics:(NSArray *)characteristics {
    for (LGCharacteristic *characteristic in characteristics) {
        if ([characteristic.UUIDString isEqualToString:kWriteWithoutResponseCharacteristicUUIDString]) {
            NSLog(@"Discovered write without response");
            self.writeWoResponseCharacteristic = characteristic;
            [self requestSignalNotifications:NO];
        } else if ([characteristic.UUIDString isEqualToString:kNotifyCharacteristicUUIDString]) {
            NSLog(@"Discovered notify");
            self.notifyCharacteristic = characteristic;
        }
    }
}

- (void)dealloc
{
    self.peripheral = nil;
    self.robotService = nil;
    self.writeWoResponseCharacteristic = nil;
    self.notifyCharacteristic = nil;
}

- (void)reset
{
    // send ALL STOP command
    NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
    char command = DRCommandTypeAllStop;
    [data appendBytes:&command length:sizeof(command)];
    [self sendData:data];
    
    NSLog(@"Sent STOP command");
}

- (void)disconnect
{
    if (self.notifyCharacteristic) {
        [self.notifyCharacteristic setNotifyValue:NO completion:nil];
    }
    [self requestSignalNotifications:NO];
    [self reset];
    self.isManuallyDisconnecting = YES;
}

#pragma mark - Commands

- (void) sendDebugCommand:(NSString *)cmd value:(NSUInteger)value
{
    if (cmd.length) {
        NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
        char command = [cmd characterAtIndex:0];
        uint8_t unint8 = (uint8_t)value;
        [data appendBytes:&command length:sizeof(command)];
        [data appendBytes:&unint8 length:sizeof(unint8)];
        [self sendData:data];
    }
}

- (void)sendRobotProperties:(DRRobotProperties *)properties
{
    _robotProperties = properties;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
    
    // [type "1" - 1]  [robot Type - 0-255 - 1] [robot color - 0-255 - 1] [code version - 0-255 - 1] [name - string - 10, terminated with a null character]
    
    char command = DRCommandTypeSetName;
    uint8_t robotType = 0,
            robotColor = properties.colorIndex,
            codeVersion = 0;
    NSData *name = [properties.name dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    char null = '\0';
    
    [data appendBytes:&command length:sizeof(command)];
    [data appendBytes:&robotType length:sizeof(robotType)];
    [data appendBytes:&robotColor length:sizeof(robotColor)];
    [data appendBytes:&codeVersion length:sizeof(codeVersion)];
    
    if (name.length > MAX_NAME_LENGTH) {
        name = [NSData dataWithBytes:name.bytes length:MAX_NAME_LENGTH];
        NSLog(@"Error: name data > %lu (%@)", (unsigned long)MAX_NAME_LENGTH, properties.name);
    }
    [data appendData:name];
    [data appendBytes:&null length:sizeof(null)]; // I don't think we really need this, sendData will pad to 14 bytes with 0s
    
//    [data setLength:PACKET_SIZE];
//    DRRobotProperties *test = [DRRobotProperties robotPropertiesWithData:data];
//    NSLog(@"test prop :%@", test);
    
    [self sendData:data];
}

- (void)requestSignalNotifications:(BOOL)active
{
    NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
    char command = DRCommandTypeRequestSignals;
    uint8_t activate = active ? 1 : 0;
    [data appendBytes:&command length:sizeof(command)];
    [data appendBytes:&activate length:sizeof(activate)];
    [self sendData:data];
}

- (void)sendLeftMotor:(CGFloat)leftMotor rightMotor:(CGFloat)rightMotor
{
    leftMotor = CLAMP(leftMotor, -255, 255);
    rightMotor = CLAMP(rightMotor, -255, 255);
    
    // [type "2" -1]  [mtrA1 - 0-255 - 1] [mtrA2 - 0-255 - 1] [mtrB1 - 0-255 - 1] [mtrB2 - 0-255 - 1]
    
    NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
    
    char command = DRCommandTypeDirectDrive;
    uint8_t mtrA1, mtrA2, mtrB1, mtrB2;
    
    if (leftMotor >= 0) {
        mtrA1 = (uint8_t)round(leftMotor);
        mtrA2 = 0;
    } else {
        mtrA1 = 0;
        mtrA2 = (uint8_t)round(-leftMotor);
    }
    
    if (rightMotor >= 0) {
        mtrB1 = (uint8_t)round(rightMotor);
        mtrB2 = 0;
    } else {
        mtrB1 = 0;
        mtrB2 = (uint8_t)round(-rightMotor);
    }
    
    [data appendBytes:&command length:sizeof(command)];
    
    [data appendBytes:&mtrA1 length:sizeof(mtrA1)];
    [data appendBytes:&mtrA2 length:sizeof(mtrA2)];
    [data appendBytes:&mtrB1 length:sizeof(mtrB1)];
    [data appendBytes:&mtrB2 length:sizeof(mtrB2)];
    
    [self sendData:data];
}

- (void)sendThrottle:(CGFloat)throttle direction:(CGFloat)direction
{
    // send all-stop instead of 0,0 because robot prefers it
    if (throttle == 0.0) {
        [self reset];
    } else {
    
        // [type "3" - 1]  [power, -100->100, 2] [rotationRate, -400->400, 2]

        NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
        char command = DRCommandTypeGyroDrive;
        
        static NSInteger maxPower = 100, maxRotationRate = 400;
        
        int16_t power = (int16_t)CLAMP(round(throttle * maxPower), -maxPower, maxPower);
        int16_t rotationRate = (int16_t)CLAMP(round(direction * maxRotationRate), -maxRotationRate, maxRotationRate);
        
        power = NSSwapShort(power);
        rotationRate = NSSwapShort(rotationRate);
        
        [data appendBytes:&command length:sizeof(command)];
        [data appendBytes:&power length:sizeof(power)];
        [data appendBytes:&rotationRate length:sizeof(rotationRate)];
        
        [self sendData:data];
    }
}

- (void) sendAutoModeCommand:(char)mode
{
    if (mode) {
        NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
        
        char command = DRCommandTypeAutoMode;
        [data appendBytes:&command length:sizeof(command)];
        [data appendBytes:&mode length:sizeof(mode)];
        
        [self sendData:data];
    }
}

- (void)setEyeColor:(UIColor *)eyeColor
{
    if (!eyeColor) {
        eyeColor = kDREyeColorOff;
    }
    
//    [type "4" -1]  [red - 0-255 - 1] [green - 0-255 - 1] [blue - 0-255 - 1]
    
    NSMutableData *data = [NSMutableData dataWithCapacity:PACKET_SIZE];
    
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha =0.0;
    [eyeColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    char command = DRCommandTypeSetEyes;
    uint8_t eyesRed = (uint8_t)(red * 255);
    uint8_t eyesGreen = (uint8_t)(green * 255);
    uint8_t eyesBlue = (uint8_t)(blue * 255);
    
    [data appendBytes:&command length:sizeof(command)];
    
    [data appendBytes:&eyesRed length:sizeof(eyesRed)];
    [data appendBytes:&eyesGreen length:sizeof(eyesGreen)];
    [data appendBytes:&eyesBlue length:sizeof(eyesBlue)];
    
    [self sendData:data];
    _eyeColor = eyeColor;
}

- (UIColor *)eyeColor {
    if (!_eyeColor) {
        _eyeColor = kDREyeColorOff;
    }
    return _eyeColor;
}

#pragma mark -
#pragma mark Characteristics interaction

- (void)setNotifyCharacteristic:(LGCharacteristic *)notifyCharacteristic
{
    _notifyCharacteristic = notifyCharacteristic;
    if (_notifyCharacteristic) {
        __weak typeof(self) weakSelf = self;
        [_notifyCharacteristic setNotifyValue:YES completion:^(NSError *error) {
            if (error) {
                NSLog(@"Error setting up notify! %@", error);
            }
        } onUpdate:^(NSData *data, NSError *error) {
            if (error) {
                NSLog(@"Problem with notify: %@", error);
            } else {
                [weakSelf handleNotifyUpdate:data];
            }
        }];
    }
}

- (void)handleNotifyUpdate:(NSData *)data
{
    if (data.length == PACKET_SIZE) {
        char msgType;
        [data getBytes:&msgType length:sizeof(msgType)];
        
        switch (msgType) {
            case DRMessageTypeSignals: {
                DRSignalPacket *signals = [DRSignalPacket signalPacketWithData:data];
                [self.delegate receivedNotifyWithSignals:signals];
                break;
            }
            case DRMessageTypeName: {
                DRRobotProperties *properties = [DRRobotProperties robotPropertiesWithData:data];
                self.robotProperties = properties;
                [self.delegate receivedNotifyWithProperties:properties];
                [self requestSignalNotifications:YES];
                break;
            }
            case DRMessageTypeAutoRunComplete: {
                [self.delegate receivedNotifyWithData:data];
                break;
            }
            default: {
                NSLog(@"Unknown message of type %c", msgType);
                [self.delegate receivedNotifyWithData:data];
                break;
            }
        }
    } else {
        NSLog(@"Notify: wrong packet size: %@", data);
        [self.delegate receivedNotifyWithData:data];
    }
}

- (void)sendData:(NSMutableData *)data
{
    if (!self.peripheral) {
        NSLog(@"Not connected to a peripheral!");
		return ;
    }
    
    if (!self.writeWoResponseCharacteristic) {
        if (self.robotService.cbService && self.robotService.cbService.characteristics.count) {
            [self discover];
            return;
        } else {
            NSLog(@"Write characteristic undefined!");
//        [self discover];
            return;
        }
    }
    
    [data setLength:PACKET_SIZE];
    [self.writeWoResponseCharacteristic writeValue:data completion:nil];
    NSLog(@"send %@", data);
}

@end
