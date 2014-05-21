//
//  PFUser+SilentFilm.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <Parse/Parse.h>

@class M3Thread;

@interface PFUser (SilentFilm)

@property NSString *nickname;
@property NSString *facebookId;

- (NSString*)channelName;
- (NSString*)channelNameForNewThreads;
- (NSString*)channelNameForNewPostInThread:(M3Thread*)thread;

@end
