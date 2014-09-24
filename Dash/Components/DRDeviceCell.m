//
//  DRDeviceCell.m
//  Dash
//
//  Created by Adam Overholtzer on 3/30/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRDeviceCell.h"

@implementation DRDeviceCell

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.imageView.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    self.imageView.image = [self.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.layer.cornerRadius = CGRectGetWidth(self.imageView.bounds)/2;
    self.imageView.layer.borderWidth = IS_RETINA == 2.0 ? 0.5 : 1;
}

- (UIViewTintAdjustmentMode)tintAdjustmentMode
{
    return UIViewTintAdjustmentModeNormal;
}

//- (void)setSelected:(BOOL)selected
//{
//    [super setSelected:selected];
//}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.alpha = 0.25;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 1;
        }];
    }
}

@end
