//
//  CAShapeLayer+Progress.h
//  Dash
//
//  Created by Adam Overholtzer on 4/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CAShapeLayer (Progress)

- (void)configureForView:(UIView *)view;
- (void)animateForDuration:(NSTimeInterval)duration;

@end
