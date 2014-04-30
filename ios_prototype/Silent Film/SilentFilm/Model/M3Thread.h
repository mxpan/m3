//
//  M3Thread.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <Parse/Parse.h>

@interface M3Thread : PFObject <PFSubclassing>

@property NSArray *users;
@property NSMutableArray *posts;

+ (void)fetchThreadsForCurrentUserWithCallback:(void (^)(NSArray*))callback;
- (void)addPostWithVideoAtURL:(NSURL*)url withBlock:(PFObjectResultBlock)block progressBlock:(PFProgressBlock)progressBlock;
- (void)fetchPostsWithCallback:(void (^)())callback;
- (PFUser*)otherUser;

@end
