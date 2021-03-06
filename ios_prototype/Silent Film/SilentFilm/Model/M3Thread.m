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
#import "M3CompiledVideo.h"

#import <Parse/PFObject+Subclass.h>
#import <AVFoundation/AVFoundation.h>
#import "PFUser+SilentFilm.h"
#import <NSArray+BlocksKit.h>

@implementation M3Thread

@synthesize posts, finalizedThumbnail;
@dynamic users, title, finalizedFilm;

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

- (void)addPostWithVideo:(M3Video*)video title:(NSString*)title withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock
{
    [video exportWithCallback:^{
        NSData *data = [NSData dataWithContentsOfURL:video.outputURL];
        PFFile *videoFile = [PFFile fileWithName:@"video.mp4" data:data];
        [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            M3Post *post = [M3Post new];
            post.user = [PFUser currentUser];
            post.video = videoFile;
            post.thread = self;
            post.title = title;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                for (PFUser *user in self.users) {
                    if (![user isEqual:[PFUser currentUser]]) {
                        PFPush *push = [[PFPush alloc] init];
                        [push setMessage:[NSString stringWithFormat:@"New video from %@!", post.user.nickname]];
                        [push setChannel:[user channelName]];
                        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            
                        }];
                    }
                }
                if (block) {
                    block(post, nil);
                }
            }];
        } progressBlock:progressBlock];
    }];
}

- (void)compileFullVideo:(M3CompiledVideo*)videoCompiler withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock
{
    [videoCompiler renderFullVideo:^{
        NSData *data = [NSData dataWithContentsOfURL:videoCompiler.outputURL];
        AVAsset *asset = [AVAsset assetWithURL:videoCompiler.outputURL];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        self.finalizedThumbnail = [UIImage imageWithCGImage:[generator copyCGImageAtTime:CMTimeMake(4, 1) actualTime:nil error:nil]];

        
        PFFile *videoFile = [PFFile fileWithName:@"video.mp4" data:data];
        [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            self.finalizedFilm = videoFile;
            [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (block) {
                    block(self, nil);
                }
            }];
        } progressBlock:progressBlock];
    }];
}

- (void)fetchPostsWithCallback:(void (^)(NSArray *newPosts))callback
{
    PFQuery *query = [M3Post query];
    [query whereKey:@"thread" equalTo:self];
    [query includeKey:@"user"];
    [query addDescendingOrder:@"createdAt"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableArray *newPosts = [NSMutableArray array];
        
        if (!self.posts) {
            self.posts = [NSMutableArray arrayWithArray:objects];
        } else {
            for (M3Post *post in objects) {
                BOOL isNew = YES;
                for (M3Post *existingPost in self.posts) {
                    if ([post.objectId isEqualToString:existingPost.objectId]) {
                        isNew = NO;
                        break;
                    }
                }
                
                if (isNew) {
                    [self.posts addObject:post];
                    [newPosts addObject:post];
                }
            }
        }

        
        if (callback) {
            callback(newPosts);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"posts" object:self];
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

- (NSURL*)webpageURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://mxpan.github.io/m3/silent_film/index.html?film=%@", self.objectId]];
}

- (NSArray *)freshPosts
{
    return [self.posts bk_select:^BOOL(M3Post *post) {
        return post.state == kFresh;
    }];
}

- (NSArray *)respondedPosts
{
    return [self.posts bk_select:^BOOL(M3Post *post) {
        return post.state >= kResponded;
    }];
}

- (NSString *)displayTitle
{
    return [NSString stringWithFormat:@"\"%@\" (w/ %@)", self.title, self.otherUser.nickname];
}

@end





