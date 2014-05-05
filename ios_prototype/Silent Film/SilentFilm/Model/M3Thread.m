//
//  M3Thread.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3Thread.h"
#import "M3Post.h"
#import "M3Video.h"

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

- (void)addPostWithVideo:(M3Video*)video withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock
{
    [video exportWithCallback:^{
        NSData *data = [NSData dataWithContentsOfURL:video.outputURL];
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
