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
#import <Social/Social.h>

@interface M3ThreadViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, FBFriendPickerDelegate>


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property UIImage *endCard;
@property NSURL *outputFileURL;
@property UIRefreshControl *refreshControl;
@property FBFriendPickerViewController *friendPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *compileButton;


@property NSTimer *refreshTimer;
@property NSString *currentTitle;

@end

@implementation M3ThreadViewController

- (id)initWithThread:(M3Thread*)thread
{
    self = [super init];
    if (self) {
        self.thread = thread;
        UIBarButtonItem *button = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"video-icon.png"] style:UIBarButtonItemStylePlain handler:^(id sender) {
//        UIBarButtonItem *button = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] bk_initWithTitle:@"Add..."];
            
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
        
        
        self.friendPicker = [FBFriendPickerViewController new];

        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSString *facebookId = result[@"id"];
            
            self.friendPicker.delegate = self;
            self.friendPicker.userID = facebookId;
            self.friendPicker.session = [PFFacebookUtils session];
            [self.friendPicker loadData];
        }];
        
        self.refreshTimer = [NSTimer bk_scheduledTimerWithTimeInterval:2.0 block:^(NSTimer *timer) {
            [self refresh];
        } repeats:YES];
    }
    return self;
}

- (void)refresh
{
    [self.tableView reloadData];
    [self.thread fetchPostsWithCallback:^(NSArray *newPosts) {
        if (newPosts.count) {
            BOOL newPostNotFromMe = NO;
            for (M3Post *post in newPosts) {
                if (![post.user isEqual:[PFUser currentUser]]) {
                    newPostNotFromMe = YES;
                }
            }
            if (newPostNotFromMe) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Message!" message:nil delegate:nil cancelButtonTitle:@"Okay!" otherButtonTitles: nil];
                [alertView show];
            }
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
    [self.thread refreshInBackgroundWithBlock:nil];
    if (self.thread.finalizedFilm) {
        [self.compileButton setTitle:@"Recompile"];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self sortPostArray:self.thread.posts];
    [self refresh];
}

- (void)dealloc
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
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
        self.currentTitle = [createCardViewController cardTitle];
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
    [self.thread addPostWithVideo:video title:self.currentTitle withBlock:^(PFObject *object, NSError *error) {
        [progressHud hide:YES];
        if ([object isKindOfClass:[M3Post class]]) {
            M3Post *post = (M3Post*)object;
            
            weakSelf.currentTitle = nil;
            
            [weakSelf.thread.posts insertObject:post atIndex:weakSelf.thread.posts.count];
            [weakSelf sortPostArray:weakSelf.thread.posts];
            
            [weakSelf.tableView reloadData];
            [weakSelf.thread refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [weakSelf.tableView reloadData];
            }];
        }
    } progressBlock:^(int percentDone) {
        progressHud.progress = percentDone / 100.0f;
    }];
}

- (void) sortPostArray:(NSMutableArray*)arr {
    [arr sortUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(M3Post*)a createdAt];
        NSDate *second = [(M3Post*)b createdAt];
        return [first compare:second];
    }];
}

- (void)showEndingCardScreen {
    M3CreateCardViewController *cardView = [[M3CreateCardViewController alloc] init];
    cardView.isTitleCard = false;
    cardView.threadViewController = self;
    [self presentViewController:cardView animated:YES completion:nil];
}

- (IBAction)createFullMovie:(UIBarButtonItem *)sender {
    [self showEndingCardScreen];
}

- (void)dismissEndingCardAndUpload: (M3CreateCardViewController *)createCardViewController {
    self.endCard = createCardViewController.image;
    [createCardViewController dismissViewControllerAnimated:YES completion:^{
        [self renderFullVideo];
    }];
}

- (void)skipEndingCard: (M3CreateCardViewController *)createCardViewController {
    self.endCard = nil;
    [createCardViewController dismissViewControllerAnimated:YES completion:^{
        [self renderFullVideo];
    }];
}

- (void)renderFullVideo{
    MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHud.mode = MBProgressHUDModeAnnularDeterminate;
    progressHud.labelText = @"Uploading video...";
    M3CompiledVideo *videoCompiler = [[M3CompiledVideo alloc] init];
    videoCompiler.posts = self.thread.posts;
    videoCompiler.outputURL = [M3AppDelegate fileURLForTemporaryFileNamed:@"final-movie.mov"];
    videoCompiler.endCard = self.endCard;
    
    [self.thread compileFullVideo:videoCompiler withBlock:^(PFObject *object, NSError *error) {
        [progressHud hide:YES];
        if ([object isKindOfClass:[M3Thread class]]) {
            M3Thread *thread = (M3Thread*)object;
            if (thread.finalizedFilm) {
                [self refresh];
                [UIAlertView bk_showAlertViewWithTitle:@"Film Complete!" message:nil cancelButtonTitle:@"Okay" otherButtonTitles:@[@"Open in Safari", @"Share to Facebook"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    NSURL *videoUrl = thread.webpageURL;
                    
                    if (buttonIndex == 1) {
                        [[UIApplication sharedApplication] openURL:videoUrl];
                    } else if (buttonIndex == 2) {
                        SLComposeViewController *compose = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                        [compose setInitialText:[NSString stringWithFormat:@"I just made this Silent Film: \"%@\"", self.thread.title]];
                        [compose addURL:videoUrl];
                        [compose addImage:self.thread.finalizedThumbnail];
                        [self presentViewController:compose animated:YES completion:nil];
                    }
                }];
            }
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
        return self.thread.users.count + 1;
    } else {
        return self.thread.posts.count;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Users";
    } else {
        return @"Scenes";
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
        [post deleteInBackground];
        [self.thread.posts removeObject:post];
        [self.tableView reloadData];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
 
    if (indexPath.section == 0) {
        if (indexPath.row < self.thread.users.count) {
            PFUser *user = [self.thread.users objectAtIndex:indexPath.row];
            cell.textLabel.text = user.nickname;
        } else {
            cell.textLabel.text = @"Add user...";
        }

    } else if (indexPath.section == 1) {
        M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%d. \"%@\" by %@", indexPath.row+1, post.title, post.user.nickname];
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
    if (indexPath.section == 0) {
        if (indexPath.row == self.thread.users.count) {
            [self presentViewController:self.friendPicker animated:YES completion:nil];
        }
    } else if (indexPath.section == 1) {
        M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
        NSURL *videoUrl = [NSURL URLWithString:post.video.url];
        MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
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

- (BOOL)checkForCompiledVideo
{
    if (!self.thread.finalizedFilm) {
        [UIAlertView bk_showAlertViewWithTitle:@"You must compile the video first!" message:@"Press Compile at the bottom left of this screen" cancelButtonTitle:@"Okay" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            
        }];
        return NO;
    }
    return YES;
}

- (IBAction)watchPressed:(id)sender {
    if (![self checkForCompiledVideo]) {
        return;
    }
    NSURL *videoUrl = [NSURL URLWithString:self.thread.finalizedFilm.url];
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
}

- (IBAction)shareButtonPressed:(id)sender
{
    if (![self checkForCompiledVideo]) {
        return;
    }
    
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[@"Check out this new video I made!", self.thread.webpageURL] applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
}


@end


