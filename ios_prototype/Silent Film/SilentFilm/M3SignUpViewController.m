//
//  M3SignUpViewController.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3SignUpViewController.h"
#import "M3LoginManager.h"
#import "PFUser+SilentFilm.h"

@interface M3SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;

@end

@implementation M3SignUpViewController

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
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitPressed:(id)sender
{
    if ([[self.nicknameTextField text] length]) {
        PFUser *currentUser = [PFUser currentUser];
        currentUser.nickname = self.nicknameTextField.text;
        [currentUser saveInBackground];
        [[NSNotificationCenter defaultCenter] postNotificationName:M3UserUpdateNotification object:nil];
    }
}

@end
