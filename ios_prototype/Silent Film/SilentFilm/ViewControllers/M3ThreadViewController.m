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

#import "AVCamViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MBProgressHUD.h>
#import <TargetConditionals.h>


@interface M3ThreadViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property UITableView *tableView;

@end

@implementation M3ThreadViewController

- (id)initWithThread:(M3Thread*)thread
{
    self = [super init];
    if (self) {
        self.thread = thread;
        
        self.tableView = [UITableView new];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addVideo)];
        [self.navigationItem setRightBarButtonItem:button];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.frame = self.view.frame;
    [self.view addSubview:self.tableView];
}

- (void)addVideo
{
#if TARGET_IPHONE_SIMULATOR
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upload test video?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
    
#else // TARGET_IPHONE_SIMULATOR
    
    AVCamViewController *avCam = [[AVCamViewController alloc] init];
    avCam.threadViewController = self;
    [self.navigationController pushViewController:avCam animated:YES];
    
#endif // TARGET_IPHONE_SIMULATOR


}

- (void)recordedVideoWithFileAtURL:(NSURL *)url
{
    MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHud.mode = MBProgressHUDModeAnnularDeterminate;
    progressHud.labelText = @"Uploading video...";
    
    M3ThreadViewController *weakSelf = self;
    [self.thread addPostWithVideoAtURL:url withBlock:^(PFObject *object, NSError *error) {
        [progressHud hide:YES];
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        if ([object isKindOfClass:[M3Post class]]) {
            M3Post *post = (M3Post*)object;
            [weakSelf.thread.posts insertObject:post atIndex:0];
            [weakSelf.tableView reloadData];
            [weakSelf.thread refreshInBackgroundWithBlock:nil];
        }
    } progressBlock:^(int percentDone) {
        progressHud.progress = percentDone / 100.0f;
    }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test7" ofType:@"mp4"];
        [self recordedVideoWithFileAtURL:[NSURL fileURLWithPath:filePath]];
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
    return self.thread.posts.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    
    M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Video by %@", [[post user] objectForKey:@"nickname"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", post.createdAt];
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    M3Post *post = [self.thread.posts objectAtIndex:indexPath.row];
    NSURL *videoUrl = [NSURL URLWithString:post.video.url];
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
    [self.navigationController pushViewController:moviePlayer animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end


