//
//  M3LoginManager.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3LoginManager.h"

NSString *const M3UserUpdateNotification = @"M3UserUpdateNotification";

@implementation M3LoginManager

+ (instancetype)sharedLoginManager
{
    static dispatch_once_t onceToken;
    static M3LoginManager *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)loginWithFacebookWithSuccess:(void (^)(PFUser*))success failure:(void (^)())failure
{
    [PFFacebookUtils logInWithPermissions:@[] block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (failure) {
                failure();
            }
        } else {
            if (success) {
                success(user);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:M3UserUpdateNotification object:nil];
        }

    }];
}

- (void)logoutWithCallback:(void (^)())callback
{
    [PFUser logOut];
    if (callback){
        callback();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:M3UserUpdateNotification object:nil];
}

@end
