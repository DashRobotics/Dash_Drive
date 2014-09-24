//
//  DRWebViewController.m
//  Dash
//
//  Created by Adam Overholtzer on 3/30/14.
//  Copyright (c) 2014 Dash Robotics. All rights reserved.
//

#import "DRWebViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

@interface DRWebViewController () <MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) NSURL *url;
@end

@implementation DRWebViewController

+ (instancetype)webViewWithUrl:(NSURL *)url
{
    DRWebViewController *wvc = [[DRWebViewController alloc] initWithNibName:@"DRWebViewController" bundle:nil];
    wvc.url = url;
    return wvc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Video volume ignores mute switch.
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
        NSLog(@"Loading URL: %@", self.url.absoluteString);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)versionString
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"DashDrive %@ (build %@)", appVersionString, appBuildString];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.scheme isEqualToString:@"mailto"]) {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                mailViewController.mailComposeDelegate = self;
                [mailViewController setToRecipients:@[@"contact@dashrobotics.com"]];
                [mailViewController setSubject:[NSString stringWithFormat:@"Feedback about %@", self.versionString]];
                [self presentViewController:mailViewController animated:YES completion:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Unable to Send Mail" message:@"This device is not configured to send email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        } else {
            // Send all other links to Safari.
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    NSLog(@"Loading %@", webView.request);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"Loaded %@", webView.request);
    
    NSString *jsInsertVersion = [NSString stringWithFormat:@"document.getElementById('dash-version-footer').innerHTML = '<p>%@</p>';", self.versionString];
    [webView stringByEvaluatingJavaScriptFromString:jsInsertVersion];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Load failed with error:\n%@", error);
    if ([error code] != NSURLErrorCancelled) {
        [[[UIAlertView alloc] initWithTitle:@"Load Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError*)error {
	
	[controller dismissViewControllerAnimated:YES completion:nil];
}

@end
