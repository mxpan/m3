//
//  M3LoginManager.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const M3UserUpdateNotification;

@interface M3LoginManager : NSObject

+ (instancetype)sharedLoginManager;

- (void)loginWithFacebookWithSuccess:(void (^)(PFUser*))success failure:(void (^)())failure;
- (void)logoutWithCallback:(void (^)())callback;

@end
