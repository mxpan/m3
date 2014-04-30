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

@interface M3ThreadListViewController () <UIAlertViewDelegate>

@property NSMutableArray *threads;

@end

@implementation M3ThreadListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Threads";
        
        UIBarButtonItem *addThreadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addThread)];
        [self.navigationItem setRightBarButtonItem:addThreadButton];
        
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPressed)];
        [self.navigationItem setLeftBarButtonItem:logoutButton];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
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

- (void)addThread
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Start new thread" message:@"Enter a nickname" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 2;
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
        NSString *username = [[[alertView textFieldAtIndex:0] text] lowercaseString];
        if (username.length) {
            PFQuery *query = [PFUser query];
            [query whereKey:@"nickname" equalTo:username];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (objects.count) {
                    PFUser *otherUser = [objects firstObject];
                    if (![otherUser isEqual:[PFUser currentUser]]) {
                        M3Thread *thread = [M3Thread new];
                        thread.users = @[otherUser, [PFUser currentUser]];
                        [self.threads addObject:thread];
                        [thread saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            [self refresh];
                            PFPush *push = [[PFPush alloc] init];
                            [push setChannel:[otherUser channelNameForNewThreads]];
                            [push setMessage:[NSString stringWithFormat:@"%@ has started a thread with you!", [PFUser currentUser][@"nickname"]]];
                            [push sendPushInBackground];
                        }];
                    }
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"User Not Found" message:@"Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                }
            }];
        }
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
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    if (self.threads.count) {
        M3Thread *thread = [self.threads objectAtIndex:indexPath.row];
        [[cell textLabel] setText:[NSString stringWithFormat:@"Thread with %@ (%@)", [[thread otherUser] objectForKey:@"nickname"], [thread objectId]]];
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



@end
