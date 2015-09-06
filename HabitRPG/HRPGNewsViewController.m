//
//  HRPGNewsViewController.m
//  Habitica
//
//  Created by viirus on 03/09/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGNewsViewController.h"
#import "HRPGAppDelegate.h"
#import "HRPGTopHeaderNavigationController.h"

@interface HRPGNewsViewController ()

@end

@implementation HRPGNewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    HRPGAppDelegate *appdelegate = (HRPGAppDelegate *) [[UIApplication sharedApplication] delegate];
    self.sharedManager = appdelegate.sharedManager;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://habitica.com/static/new-stuff"]];
    self.newsWebView.delegate = self;
    [self.newsWebView loadRequest:request];
    [self.loadingIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.4 animations:^() {
        self.newsWebView.alpha = 1;
        self.loadingIndicator.alpha = 0;
    }];
    if ([[self.sharedManager getUser].habitNewStuff boolValue]) {
        [self.sharedManager updateUser:@{@"flags.newStuff": @NO} onSuccess:^() {
        }onError:^() {
        }];
    }
}


@end
