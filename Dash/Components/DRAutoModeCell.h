//
//  DRAutoModeCell.h
//  Dash
//
//  Created by Adam Overholtzer on 4/27/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DRAutoModeCell : UICollectionViewCell

@property (strong, nonatomic) UIColor *selectedColor;

- (void)setTitle:(NSString *)title image:(UIImage *)image;

@end
