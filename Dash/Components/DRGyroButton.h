//
//  DRGyroButton.h
//  Dash
//
//  Created by Adam Overholtzer on 4/20/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DRButton.h"

@interface DRGyroButton : DRButton

@property CGFloat buttonPadding;
@property (strong, nonatomic, readonly) NSArray *buttons;

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
- (void)reset;
@end
