//
//  M3Thread.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3Thread.h"
#import "M3Post.h"
#import <Parse/PFObject+Subclass.h>
#import <AVFoundation/AVFoundation.h>
#import "PFUser+SilentFilm.h"

@implementation M3Thread

@synthesize posts;
@dynamic users;

+ (NSString*)parseClassName
{
    return @"Thread";
}

+ (void)fetchThreadsForCurrentUserWithCallback:(void (^)(NSArray*))callback
{
    PFQuery *query = [M3Thread query];
    [query whereKey:@"users" equalTo:[PFUser currentUser]];
    [query includeKey:@"users"];
    
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (callback) {
            callback(objects);
        }
        for (M3Thread *thread in objects) {
            [thread fetchPostsWithCallback:nil];
        }
    }];
}

- (void)addPostWithVideoAtURL:(NSURL*)url withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock;
{
    NSURL *outputUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie-medium" stringByAppendingPathExtension:@"mov"]]];
    [self convertVideoToLowQuailtyWithInputURL:url outputURL:outputUrl handler:^(AVAssetExportSession *session) {
        NSData *data = [NSData dataWithContentsOfURL:outputUrl];
        PFFile *videoFile = [PFFile fileWithName:@"video.mp4" data:data];
        [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            M3Post *post = [M3Post new];
            post.user = [PFUser currentUser];
            post.video = videoFile;
            post.thread = self;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                PFPush *push = [[PFPush alloc] init];
                [push setMessage:[NSString stringWithFormat:@"New video from %@!", post.user[@"nickname"]]];
                [push setChannel:[self.otherUser channelName]];
                [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (block) {
                        block(post, nil);
                    }
                }];
            }];
        } progressBlock:progressBlock];
    }];
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
                                     handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        handler(exportSession);
    }];
}

- (void)fetchPostsWithCallback:(void (^)())callback
{
    PFQuery *query = [M3Post query];
    [query whereKey:@"thread" equalTo:self];
    [query includeKey:@"user"];
    [query addDescendingOrder:@"createdAt"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.posts = [NSMutableArray arrayWithArray:objects]    ;
        if (callback) {
            callback();
        }
    }];
}

- (PFUser*)otherUser
{
    if (self.users) {
        for (PFUser *user in self.users) {
            if (![user.objectId isEqualToString:[PFUser currentUser].objectId]) {
                return user;
            }
        }
    }
    return nil;
}

@end
