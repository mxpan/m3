//
//  M3LoginViewController.m
//  Silent Film
//
//  Created by Max Meyers on 4/28/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3LoginViewController.h"
#import "M3LoginManager.h"

@interface M3LoginViewController ()

@end

@implementation M3LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [self updateButton];
}

- (void)updateButton
{
    [self.loginButton setTitle:([PFUser currentUser] == nil ? @"Login with Facebook" : @"Logout") forState:UIControlStateNormal];
}


- (IBAction)loginButtonPressed:(id)sender
{
    if ([PFUser currentUser]) {
        [[M3LoginManager sharedLoginManager] logoutWithCallback:^{
            [self updateButton];
        }];

    } else {
        [[M3LoginManager sharedLoginManager] loginWithFacebookWithSuccess:nil failure:nil];
    }

}

@end
