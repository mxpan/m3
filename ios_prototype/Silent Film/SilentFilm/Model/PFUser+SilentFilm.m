//
//  PFUser+SilentFilm.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "PFUser+SilentFilm.h"
#import "M3Thread.h"

@implementation PFUser (SilentFilm)

@dynamic facebookId, nickname;

- (NSString*)channelName
{
    return [NSString stringWithFormat:@"user_%@", self.objectId];
}

- (NSString*)channelNameForNewThreads
{
    return [NSString stringWithFormat:@"new-thread_%@", self.objectId];
}

- (NSString*)channelNameForNewPostInThread:(M3Thread*)thread
{
    return [NSString stringWithFormat:@"new-post_%@_%@", self.objectId, thread.objectId];
}

- (BOOL)isEqualToCurrentUser
{
    return [self isEqualToUser:[PFUser currentUser]];
}

- (BOOL)isEqualToUser:(PFUser*)user
{
    return [self.objectId isEqualToString:user.objectId];
}

- (NSString *)firstName
{
    NSArray *names = [self.nickname componentsSeparatedByString:@" "];
    if (names.count) {
        return [names firstObject];
    }
    return @"";
}

@end
