//
//  M3ThreadViewController.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3ThreadViewController.h"
#import "M3Thread.h"
#import "M3Post.h"
#import "M3CreateCardViewController.h"
#import "M3AppDelegate.h"

#import "AVCamViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MBProgressHUD.h>
#import <TargetConditionals.h>
#import "M3Video.h"
#import "M3CompiledVideo.h"
#import <BlocksKit+UIKit.h>

#import <FacebookSDK/FacebookSDK.h>
#import "PFUser+SilentFilm.h"

@interface M3ThreadViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, FBFriendPickerDelegate>


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property UIImage *endCard;
@property NSURL *outputFileURL;
@property UIRefreshControl *refreshControl;

@end

@implementation M3ThreadViewController

- (id)initWithThread:(M3Thread*)thread
{
    self = [super init];
    if (self) {
        self.thread = thread;
        UIBarButtonItem *button = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:@"Add..."];
            [actionSheet bk_addButtonWithTitle:@"A user" handler:^{
                [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    NSString *facebookId = result[@"id"];
                    
                    FBFriendPickerViewController *friendPicker = [FBFriendPickerViewController new];
                    friendPicker.delegate = self;
                    friendPicker.userID = facebookId;
                    friendPicker.session = [PFFacebookUtils session];
                    [friendPicker loadData];
                    
                    [self presentViewController:friendPicker animated:YES completion:nil];
                    
                }];
            }];
            
            [actionSheet bk_addButtonWithTitle:@"A video" handler:^{
                [self showTitleCardScreen];
            }];
            
            [actionSheet bk_addButtonWithTitle:@"Cancel" handler:^{
                [actionSheet dismissWithClickedButtonIndex:2 animated:YES];
            }];
            
            [actionSheet showInView:self.view];
        }];
        [self.navigationItem setRightBarButtonItem:button];
        self.title = self.thread.title;
    }
    return self;
}

- (void)refresh
{
    [self.tableView reloadData];
    [self.thread fetchPostsWithCallback:^(NSArray *newPosts) {
        if (newPosts.count) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Message!" message:nil delegate:nil cancelButtonTitle:@"Okay!" otherButtonTitles: nil];
            [alertView show];
        }
        [self.tableView reloadData];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)showTitleCardScreen {
    M3CreateCardViewController *cardView = [[M3CreateCardViewController alloc] init];
    cardView.isTitleCard = true;
    cardView.threadViewController = self;
    [self presentViewController:cardView animated:YES completion:nil];
}

- (void)addVideo
{
    
#if TARGET_IPHONE_SIMULATOR
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upload test video?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
    
#else // TARGET_IPHONE_SIMULATOR
    
    AVCamViewController *avCam = [[AVCamViewController alloc] init];
    avCam.threadViewController = self;
    [self presentViewController:avCam animated:YES completion:nil];
    
#endif // TARGET_IPHONE_SIMULATOR
}

- (void)createCardViewControllerFinished:(M3CreateCardViewController*)createCardViewController
{
    if (createCardViewController.isTitleCard) {
        self.titleCard = createCardViewController.image;
    } else {
        self.endCard = createCardViewController.image;
    }
    
    [self dismissCardViewController:createCardViewController];
}

- (void) dismissCardViewController:(M3CreateCardViewController *)createCardViewController {
    if (createCardViewController.isTitleCard){
        [createCardViewController dismissViewControllerAnimated:YES completion:^{
            [self addVideo];
        }];
    } else {
        [createCardViewController dismissViewControllerAnimated:YES completion:^{
            [self recordedVideoWithFileAtURL:self.outputFileURL];
        }];
    }
}

- (void)dismissAvCam: (AVCamViewController*)avCamVc {
    self.outputFileURL = avCamVc.outputFileURL;
    [avCamVc dismissViewControllerAnimated:YES completion:^{
        [self recordedVideoWithFileAtURL:self.outputFileURL];
    }];
}

- (void)recordedVideoWithFileAtURL:(NSURL *)url
{
    MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHud.mode = MBProgressHUDModeAnnularDeterminate;
    progressHud.labelText = @"Uploading video...";
    
    M3Video *video = [M3Video new];
    video.titleCard =  self.titleCard;
    video.video = [AVAsset assetWithURL:url];
    video.outputURL = [M3AppDelegate fileURLForTemporaryFileNamed:@"final-movie.mov"];
    
    M3ThreadViewController *weakSelf = self;
    [self.thread addPostWithVideo:video withBlock:^(PFObject *object, NSError *error) {
        [progressHud hide:YES];
        if ([object isKindOfClass:[M3Post class]]) {
            M3Post *post = (M3Post*)object;
            [weakSelf.thread.posts insertObject:post atIndex:weakSelf.thread.posts.count];
            [weakSelf.tableView reloadData];
            [weakSelf.thread refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [weakSelf.tableView reloadData];
            }];
        }
    } progressBlock:^(int percentDone) {
        progressHud.progress = percentDone / 100.0f;
    }];

}

- (IBAction)createFullMovie:(UIBarButtonItem *)sender {
    MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHud.mode = MBProgressHUDModeAnnularDeterminate;
    progressHud.labelText = @"Uploading video...";
    M3CompiledVideo *videoCompiler = [[M3CompiledVideo alloc] init];
    videoCompiler.posts = self.thread.posts;
    videoCompiler.outputURL = [M3AppDelegate fileURLForTemporaryFileNamed:@"final-movie.mov"];
    
    M3ThreadViewController *weakSelf = self;
    [self.thread compileFullVideo:videoCompiler withBlock:^(PFObject *object, NSError *error) {
        [progressHud hide:YES];
        if ([object isKindOfClass:[M3Post class]]) {
            M3Post *post = (M3Post*)object;
            [weakSelf.thread.posts insertObject:post atIndex:weakSelf.thread.posts.count];
            [weakSelf.tableView reloadData];
            [weakSelf.thread refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [weakSelf.tableView reloadData];
            }];
        }
    } progressBlock:^(int percentDone) {
        progressHud.progress = percentDone / 100.0f;
    }];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"test7" withExtension:@"mp4"];
        AVCamViewController *avCam = [AVCamViewController new];
        avCam.outputFileURL = fileURL;
        [self presentViewController:avCam animated:NO completion:^{
            [self dismissAvCam:avCam];
        }];
    }
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.thread.users.count;
    } else {
        return self.thread.posts.count;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Users";
    } else {
        return @"Posts";
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
 
    if (indexPath.section == 0) {
        PFUser *user = [self.thread.users objectAtIndex:indexPath.row];
        cell.textLabel.text = user.nickname;
    } else if (indexPath.section == 1) {
        M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"Video by %@", post.user.nickname];
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"MMM dd, yyyy hh:mm a"];
        NSString *dateString = [format stringFromDate:post.createdAt];
        
        cell.detailTextLabel.text = dateString;
    }
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
        NSURL *videoUrl = [NSURL URLWithString:post.video.url];
        MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
        
        //    [[NSNotificationCenter defaultCenter] removeObserver:moviePlayer
        //                                                    name: MPMoviePlayerPlaybackDidFinishNotification
        //                                                  object:moviePlayer.moviePlayer];
        //
        
        [self presentMoviePlayerViewControllerAnimated:moviePlayer];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark FBFriendPicker

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
    
    [picker dismissViewControllerAnimated:YES completion:^{
        PFQuery *query = [PFUser query];
        [query whereKey:@"facebookId" containedIn:[NSArray arrayWithArray:facebookIds]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSMutableArray *currentUsers = [NSMutableArray arrayWithArray:[self.thread users]];
            NSMutableArray *newUsers = [NSMutableArray array];
            
            for (PFUser *user in objects) {
                BOOL existing = NO;
                for (PFUser *currentUser in currentUsers) {
                    if ([user isEqual:currentUser]) {
                        existing = YES;
                    }
                }
                
                if (!existing) {
                    [newUsers addObject:user];
                    [currentUsers addObject:user];
                }
            }
            
            for (PFUser *newUser in newUsers) {
                PFPush *push = [[PFPush alloc] init];
                [push setChannel:[newUser channelNameForNewThreads]];
                [push setMessage:[NSString stringWithFormat:@"%@ has started a thread with you!", [PFUser currentUser].nickname]];
                [push sendPushInBackground];
            }
            
            self.thread.users = currentUsers;
            [self.thread saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self refresh];
            }];
        }];
    }];
    
}

@end


