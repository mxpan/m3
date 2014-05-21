//
//  M3MainViewController.m
//  Silent Film
//
//  Created by Max Meyers on 4/28/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3MainViewController.h"

#import "M3LoginViewController.h"
#import "M3ThreadListViewController.h"
#import "M3NavigationController.h"
#import "M3SignUpViewController.h"

#import "M3LoginManager.h"
#import "PFUser+SilentFilm.h"

@interface M3MainViewController ()

@property M3LoginViewController *loginViewController;

@property M3ThreadListViewController *threadListViewController;
@property M3NavigationController *threadListNavigationController;
@property M3SignUpViewController *signUpViewController;

@end

@implementation M3MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.loginViewController = [M3LoginViewController new];
        
        self.threadListViewController = [M3ThreadListViewController new];
        self.threadListNavigationController = [[M3NavigationController alloc] initWithRootViewController:self.threadListViewController];
        self.signUpViewController = [M3SignUpViewController new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:M3UserUpdateNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh];
}

- (void)refresh
{
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    
    if ([PFUser currentUser]) {
        PFInstallation *installation = [PFInstallation currentInstallation];
        [installation addUniqueObject:[[PFUser currentUser] channelNameForNewThreads] forKey:@"channels"];
        [installation addUniqueObject:[[PFUser currentUser] channelName] forKey:@"channels"];
        [installation saveInBackground];
        
        NSString *nickname = [[PFUser currentUser] nickname];
        if (nickname && ![nickname isEqualToString:@""]) {
            [self.view addSubview:self.threadListNavigationController.view];
        } else {
            [self.view addSubview:self.signUpViewController.view];
        }
    } else {
        [self.view addSubview:self.loginViewController.view];
    }
}

@end
