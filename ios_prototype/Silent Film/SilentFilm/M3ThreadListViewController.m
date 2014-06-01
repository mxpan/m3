//
//  M3ThreadListViewController.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3ThreadListViewController.h"
#import "M3Thread.h"
#import "M3ThreadViewController.h"
#import "M3LoginManager.h"
#import "PFUser+SilentFilm.h"
#import <UIAlertView+BlocksKit.h>
#import <MBProgressHUD.h>
#import "M3ThreadTableViewCell.h"

@interface M3ThreadListViewController () <UIAlertViewDelegate, FBFriendPickerDelegate>

@property NSMutableArray *threads;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property UIRefreshControl *refreshControl;

@property FBFriendPickerViewController *friendPicker;
@property NSString *currentTitle;

@end

@implementation M3ThreadListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Current Games";
        
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPressed)];
        [self.navigationItem setLeftBarButtonItem:logoutButton];
        
        self.friendPicker = [FBFriendPickerViewController new];
        
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSString *facebookId = result[@"id"];
            
            self.friendPicker.delegate = self;
            self.friendPicker.userID = facebookId;
            self.friendPicker.session = [PFFacebookUtils session];
            self.friendPicker.allowsMultipleSelection = NO;
            [self.friendPicker loadData];
        }];
    }
    return self;
}

- (IBAction)createThreadButtonPressed:(id)sender
{
    [self.friendPicker clearSelection];
    [self presentViewController:self.friendPicker animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"M3ThreadTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    self.tableView.rowHeight = 80;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)logoutButtonPressed
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to logout?" message:[NSString stringWithFormat:@""] delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Yes!", nil];
    alertView.tag = 1;
    
    [alertView show];
}

- (void)refresh
{
    [M3Thread fetchThreadsForCurrentUserWithCallback:^(NSArray *objects) {
        self.threads = [NSMutableArray arrayWithArray:objects];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}


#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [[M3LoginManager sharedLoginManager] logoutWithCallback:nil];
        }
    } else if (alertView.tag == 2 && buttonIndex == 1) {
        NSString *title = [[alertView textFieldAtIndex:0] text];
        self.currentTitle = title;
        [self.friendPicker clearSelection];
        [self presentViewController:self.friendPicker animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MAX(1, self.threads.count);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        M3Thread *thread = [self.threads objectAtIndex:indexPath.row];
        [thread deleteInBackground];
        [self.threads removeObject:thread];
        [self.tableView reloadData];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    M3ThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (self.threads.count) {
        M3Thread *thread = [self.threads objectAtIndex:indexPath.row];
        cell.titleLabel.text = thread.otherUser.nickname;
        cell.thread = thread;
    }
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    M3Thread *thread = [self.threads objectAtIndex:indexPath.row];
    M3ThreadViewController *threadVC = [[M3ThreadViewController alloc] initWithThread:thread];
    [self.navigationController pushViewController:threadVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    [sender dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(FBFriendPickerViewController*)picker
{
    

    NSMutableArray *facebookIds = [NSMutableArray array];
    for (id<FBGraphUser> user in [picker selection]) {
        NSLog(@"User ID: %@", [user objectID]);
        [facebookIds addObject:[user objectID]];
    }

    if (facebookIds.count) {
        [picker dismissViewControllerAnimated:YES completion:^{
            
            MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            PFQuery *query = [PFUser query];
            [query whereKey:@"facebookId" containedIn:[NSArray arrayWithArray:facebookIds]];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                PFUser *otherUser = [objects firstObject];
                
                for (M3Thread *thread in self.threads) {
                    if ([thread.otherUser.objectId isEqualToString:otherUser.objectId]) {
                        [progress hide:YES];
                        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.threads indexOfObject:thread] inSection:0]];
                        return;
                    }
                }

                M3Thread *thread = [M3Thread new];
                thread.users = @[[PFUser currentUser], otherUser];
                thread.title = self.currentTitle;
                [self.threads addObject:thread];
                
                PFPush *push = [[PFPush alloc] init];
                [push setChannel:[otherUser channelNameForNewThreads]];
                [push setMessage:[NSString stringWithFormat:@"%@ has started a challenge thread with you!", [PFUser currentUser].nickname]];
                [push sendPushInBackground];
                
                [thread saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [self refresh];
                    [progress hide:YES];
                }];
            }];
        }];
    } else {
        [UIAlertView bk_showAlertViewWithTitle:@"Must include at least one friend!" message:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil handler:nil];
    }
    
}



@end
