//
//  M3AppDelegate.m
//  Silent Film
//
//  Created by Max Meyers on 4/28/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3AppDelegate.h"
#import "M3MainViewController.h"

#import "M3Thread.h"
#import "M3Post.h"

@implementation M3AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [M3Thread registerSubclass];
    [M3Post registerSubclass];
    
    [Parse setApplicationId:@"Eo7LBKUkahGvWbiu6Q9sAJmiQgfrmxOhr8pikEr3"
                  clientKey:@"kgmgz8sYk5gz6tEaZP8H7iOsHGXlDUuTCVwjL89x"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [PFFacebookUtils initializeFacebook];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *vc = [M3MainViewController new];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
        
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [PFPush handlePush:userInfo];
}

@end
