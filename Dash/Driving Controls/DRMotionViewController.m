//
//  DRMotionViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 3/1/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRMotionViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "DRCentralManager.h"
#import "DRSignalPacket.h"

static CGFloat MAX_JOYSTICK_TRAVEL = 100;

@interface DRMotionViewController () {
    BOOL _touchDown;
    CGPoint _touchOffset;
    CGFloat _sliderPosition, _throttle, _direction, _prevThrottle, _prevDirection;
    NSTimer *_updateTimer;
}
@property (weak, nonatomic) IBOutlet UIView *sliderTouchArea;
@property (weak, nonatomic) IBOutlet UIImageView *sliderHead;
@property (weak, nonatomic) IBOutlet UIView *rotatedView;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMAttitude *referenceAttitude;
- (IBAction)resetAttitude;
@end

@implementation DRMotionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.05;
    
    _sliderPosition = 0;
    [self updateThrottle:0 direction:0];
    self.sliderHead.layer.cornerRadius = CGRectGetHeight(self.sliderHead.bounds) / 2;
    
    self.rotatedView.transform = CGAffineTransformMakeRotation(M_PI_2);
}

- (void)sendUpdate
{
    if (_prevThrottle != _throttle || _prevDirection != _direction) {
        if (self.bleService.useGyroDrive) {
            [self.bleService sendThrottle:_throttle direction:_direction];
        } else {
            CGFloat leftMotor = CLAMP(_throttle * (1.0 + _direction), -1.0, 1.0) * 255.0;
            CGFloat rightMotor = CLAMP(_throttle * (1.0 - _direction), -1.0, 1.0) * 255.0;
            [self.bleService sendLeftMotor:leftMotor rightMotor:rightMotor];
        }
        _prevThrottle = _throttle;
        _prevDirection = _direction;
    }
}

- (void)viewDidLayoutSubviews {
    self.sliderHead.center = self.sliderTouchArea.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    _bleService.delegate = self;
    
    if (!_updateTimer || !_updateTimer.isValid) {
        _updateTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(sendUpdate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_updateTimer forMode:NSRunLoopCommonModes];
    }
    
    if (self.motionManager.isDeviceMotionAvailable) {
        [self resetAttitude];
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
                                                                toQueue:[NSOperationQueue mainQueue]
                                                            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                                if (!error && weakSelf)
                                                                    [weakSelf updateThrottle:_sliderPosition
                                                                                   direction:[weakSelf getDirection:motion.attitude]];
                                                            }];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.motionManager stopDeviceMotionUpdates];
    [_updateTimer invalidate];
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    self.motionManager = nil;
    self.referenceAttitude = nil;
}

- (IBAction)resetAttitude {
    self.referenceAttitude = self.motionManager.deviceMotion.attitude;
}

- (void)updateThrottle:(CGFloat)throttle direction:(CGFloat)direction
{
//    if (direction > -0.1 && direction < 0.1) direction = 0;
    throttle = -throttle;
    
    _throttle = throttle;
    _direction = direction;
    
//    CGFloat leftMotor = CLAMP(throttle * (1.0 + direction), -1.0, 1.0) * 255.0;
//    CGFloat rightMotor = CLAMP(throttle * (1.0 - direction), -1.0, 1.0) * 255.0;
//    
//    self.debugLabel.text = [NSString stringWithFormat:@"%.0f, %.0f", roundf(leftMotor), roundf(rightMotor)];
//    self.debugLabel.text = [self.debugLabel.text stringByReplacingOccurrencesOfString:@"-0" withString:@"0"];
//    
//    [self.bleService setLeftMotor:leftMotor rightMotor:rightMotor];
}

- (CGFloat)getDirection:(CMAttitude *)attitude
{
    if (self.referenceAttitude) {
        [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
        return CLAMP(attitude.yaw/M_PI_2, -1.0, 1.0);
    } else {
        return 0;
    }
}

- (void)resetSliderToZero
{
    _touchDown = NO;
    _sliderPosition = 0;
    [self updateThrottle:_sliderPosition
               direction:[self getDirection:self.motionManager.deviceMotion.attitude]];
    
    [UIView animateWithDuration:0.1 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.sliderHead.center = self.sliderTouchArea.center;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (IS_IPAD) {
        [self resetAttitude];
    }
}

- (void)receivedNotifyWithData:(NSData *)data
{
    self.debugLabel.text = [data description];
}

- (void)receivedNotifyWithSignals:(DRSignalPacket *)signals
{
    self.debugLabel.text = [signals description];
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touch = [[touches anyObject] locationInView:self.view];
    if (CGRectContainsPoint(self.sliderTouchArea.frame, touch)) {
        _touchDown = YES;
        if (!CGRectContainsPoint(self.sliderHead.frame, touch)) {
            _touchOffset = CGPointZero;
            [self touchesMoved:touches withEvent:event];
        } else {
            _touchOffset = CGPointMake(touch.x - self.sliderHead.center.x, self.sliderHead.center.y);
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touchDown) {
        CGPoint touch = [[touches anyObject] locationInView:self.view];
        CGPoint kCenter = self.sliderTouchArea.center;
        CGFloat dx = touch.x - kCenter.x;
        
        dx = CLAMP(dx, -MAX_JOYSTICK_TRAVEL, MAX_JOYSTICK_TRAVEL);
        _sliderPosition = dx / MAX_JOYSTICK_TRAVEL;
        
        [self updateThrottle:_sliderPosition
                   direction:[self getDirection:self.motionManager.deviceMotion.attitude]];
        
        self.sliderHead.center = CGPointMake(kCenter.x + dx, self.sliderHead.center.y);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self resetSliderToZero];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self resetSliderToZero];
}

@end
