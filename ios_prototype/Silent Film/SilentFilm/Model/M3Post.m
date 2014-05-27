//
//  M3Post.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3Post.h"
#import <Parse/PFObject+Subclass.h>

@implementation M3Post

@dynamic thread, user, video, title;

+ (NSString*) parseClassName
{
    return @"Post";
}

@end
