//
//  CAShapeLayer+Progress.m
//  Dash
//
//  Created by Adam Overholtzer on 4/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "CAShapeLayer+Progress.h"

@implementation CAShapeLayer (Progress)

- (void)configureForView:(UIView *)view
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, CGRectGetHeight(view.bounds)-1);
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(view.bounds)*1.05, CGRectGetHeight(view.bounds)-1);
    
    self.frame = view.bounds;
    self.path = path;
    self.fillColor = nil;
    self.lineWidth = 2;
    self.strokeEnd = 0;
    self.strokeColor = [DR_DARK_GRAY colorWithAlphaComponent:0.666].CGColor;
}

- (void)animateForDuration:(NSTimeInterval)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = duration;
    animation.fromValue = @0.0;
    animation.toValue = @1.0;
    animation.removedOnCompletion = YES;
    [self addAnimation:animation forKey:@"strokeEnd"];
}

@end
