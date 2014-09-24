//
//  DRButton.m
//  Dash
//
//  Created by Adam Overholtzer on 4/6/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRButton.h"

@implementation DRButton

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.alpha = 1.0;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.alpha = 0.25;
    } else {
        [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alpha = self.enabled ? 1.0 : 0.25;
        } completion:nil];
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [self setEnabled:enabled animated:YES];
}

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated
{
    [super setEnabled:enabled];
    
    if (animated) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alpha = enabled ? 1.0 : 0.25;
        } completion:nil];
    } else {
        self.alpha = enabled ? 1.0 : 0.25;
    }
}

@end
