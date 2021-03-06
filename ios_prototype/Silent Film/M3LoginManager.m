//
//  M3LoginManager.m
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3LoginManager.h"
#import "PFUser+SilentFilm.h"

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
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                NSString *fbId = result[@"id"];
                user.facebookId = fbId;
                user.nickname = result[@"name"];
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (success) {
                        success(user);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:M3UserUpdateNotification object:nil];
                }];
            }];
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
