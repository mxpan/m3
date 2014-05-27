//
//  M3Thread.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <Parse/Parse.h>

@class M3Video;
@class M3CompiledVideo;

@interface M3Thread : PFObject <PFSubclassing>

@property NSString *title;
@property NSArray *users;
@property NSMutableArray *posts;
@property PFFile *finalizedFilm;
@property UIImage *finalizedThumbnail;

+ (void)fetchThreadsForCurrentUserWithCallback:(void (^)(NSArray*))callback;
- (void)addPostWithVideo:(M3Video*)video title:(NSString*)title withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock;
- (void)fetchPostsWithCallback:(void (^)(NSArray *newPosts))callback;
- (PFUser*)otherUser;
- (void)compileFullVideo:(M3CompiledVideo*)videoCompiler withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock;
- (NSURL*)webpageURL;

@end
