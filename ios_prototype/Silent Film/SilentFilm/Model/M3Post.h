//
//  M3Post.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//
#import <Parse/Parse.h>

@class M3Thread, M3User;

typedef enum {
    kFresh,
    kResponded,
    kResponseViewed
} PostState;

@interface M3Post : PFObject <PFSubclassing>

@property M3Thread *thread;
@property PFUser *user;
@property PFFile *video;
@property NSString *title;
@property PostState state;
@property PFFile *thumbnail;

@end
