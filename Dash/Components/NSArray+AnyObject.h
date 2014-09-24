//
//  NSArray+AnyObject.h
//  Dash
//
//  Created by Adam Overholtzer on 4/18/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (AnyObject)
- (id)anyObject;
@end

@implementation NSArray (AnyObject)

- (id)anyObject {
    if (self.count > 0) {
        return self[arc4random_uniform((u_int32_t)self.count)];
    } else {
        return nil;
    }
}

@end