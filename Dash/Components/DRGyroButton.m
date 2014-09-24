//
//  DREyeColorButton.m
//  Dash
//
//  Created by Adam Overholtzer on 4/20/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRGyroButton.h"
#import "DRCentralManager.h"
#import "DRRobotLeService.h"

#define kGyroOnIcon IS_IPAD ? @"gyro" : @"gyro"
#define kGyroOffIcon IS_IPAD ? @"gyro" : @"gyro"

@interface DRGyroButton ()
@property (weak, nonatomic) DRRobotLeService *bleService;
@property (strong, nonatomic, readwrite) NSArray *buttons;
@end

@interface UIColor (changeBrightness)
- (UIColor *)lighterColor;
@end

@implementation UIColor (changeBrightness)
- (UIColor *)lighterColor
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}
@end

@implementation DRGyroButton

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.buttons.count) {
        [self globalInit];
    }
}

- (void)reset {
    BOOL eyeOpen = self.bleService.eyeColor && ![self.bleService.eyeColor isEqual:kDREyeColorOff];
    [self configureGyroColor:eyeOpen color:self.bleService.eyeColor];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.selected && IS_IPAD && self.buttons.count) {
        self.selected = NO;
        [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            for (UIButton *button in self.buttons) {
                button.center = self.center;
                button.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [self reset];
        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    for (UIButton *button in self.buttons) {
        button.center = self.center; // reset to new orientation
    }
}

- (void)globalInit
{
    self.bleService = [[DRCentralManager sharedInstance] connectedService];

    self.buttonPadding = 7;

    [self addTarget:self action:@selector(didTapGyroButton:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.backgroundColor = kDREyeColorOff;
        
        
    self.tintColor = [UIColor greenColor];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *GyroPref = @"Gyro-pref";
    if ([prefs boolForKey:GyroPref])
        self.tintColor = [UIColor greenColor];
    else
        self.tintColor = [UIColor redColor];
        
    [self setImage:[[UIImage imageNamed:kGyroOffIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds)/2;
    
    
    NSArray *colors = @[
                        [UIColor greenColor],
                        [UIColor redColor]
                        ];
    
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSUInteger i = 0; i < colors.count; i++) {
        UIButton *button = [[DRButton alloc] initWithFrame:self.frame];
        button.backgroundColor = colors[i];
        button.layer.cornerRadius = CGRectGetHeight(self.bounds)/2;
        if ([button.backgroundColor isEqual:[UIColor whiteColor]]) {
            button.layer.borderColor = [UIColor grayColor].CGColor;
            button.layer.borderWidth = 0.5;
        }
        button.alpha = 0;
        [button addTarget:self action:@selector(didTapGyroButton:) forControlEvents:UIControlEventTouchUpInside];
        
        if (buttons.count) {
            [self.superview insertSubview:button belowSubview:buttons.lastObject];
        } else {
            [self.superview insertSubview:button belowSubview:self];
        }
        
        [buttons addObject:button];
    }
    self.buttons = [NSArray arrayWithArray:buttons];
        
}

- (IBAction)didTapGyroButton:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *alreadyRun = @"already-run";
    if (![prefs boolForKey:alreadyRun]){
        [prefs setBool:YES forKey:alreadyRun];
        UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Gyro Control!"
                          message:@"You pressed the gyro button! Dash is now using its internal gyroscope to help him steer. If this isn't working for whatever reason, you can turn it off here. Green means Dash is using the gyro to help steer. Red means Dash ignores the gyro."
                          delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Got It!", nil];
        [alert show];
    }

    
    static NSTimeInterval kDRAnimationTotalTime = 0.36;
    self.alpha = 1;
    
    if (self.selected) {
        self.selected = NO;
        if (self.bleService) {
            if (sender == self) {
//                [self.bleService setEyeColor:kDREyeColorOff];
            } else {
                if ([[sender backgroundColor] isEqual:[UIColor redColor]]) {
                    self.bleService.useGyroDrive = NO;
                    NSString *GyroPref = @"Gyro-pref";
                    [prefs setBool:NO forKey:GyroPref];
                }
                else {
                    self.bleService.useGyroDrive = YES;
                    NSString *GyroPref = @"Gyro-pref";
                    [prefs setBool:YES forKey:GyroPref];
                }
//                [self.bleService setEyeColor:[sender backgroundColor]];
            }
        }
        
        [UIView animateWithDuration:kDRAnimationTotalTime-0.09 delay:0
             usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                 for (NSUInteger i = 0; i < self.buttons.count; i++) {
                     UIButton *button = self.buttons[i];
                     button.center = self.center;
                     if (button != sender) button.alpha = 0;
                 }
                 [self configureGyroColor:(sender != self) color:[sender backgroundColor]];
             } completion:^(BOOL finished) {
                 if (sender != self) {
                     [sender setAlpha:0];
                 }
             }];
    } else {
        self.selected = YES;
        self.tintColor = [UIColor whiteColor];
        [UIView animateWithDuration:kDRAnimationTotalTime delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.center = CGPointMake(self.center.x - (CGRectGetWidth(self.bounds)+self.buttonPadding)*(i+1), self.center.y);
                button.alpha = 1;
            }
        } completion:nil];
    }
}

- (void)configureGyroColor:(BOOL)open color:(UIColor *)color {
    if (open) {
        if (!color) {
            color = [UIColor greenColor];
        }
                
        if ([color isEqual:[UIColor redColor]]) {
            // red button
            self.tintColor = [color lighterColor];
        } else {    // green button
            self.tintColor = [color lighterColor];
        }
        [self setImage:[[UIImage imageNamed:kGyroOnIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {    // No new color chosen
        self.tintColor = [UIColor greenColor];
        [self setImage:[[UIImage imageNamed:kGyroOffIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
}


@end
