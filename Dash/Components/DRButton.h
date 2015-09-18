//
//  DRButton.h
//  Dash
//
//  Created by Adam Overholtzer on 4/6/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface DRButton : UIButton

@property (weak, nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated;

@end
