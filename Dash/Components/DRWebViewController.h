//
//  DRWebViewController.h
//  Dash
//
//  Created by Adam Overholtzer on 3/30/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DRWebViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

+ (instancetype)webViewWithUrl:(NSURL *)url;

@end
