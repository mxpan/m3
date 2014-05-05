//
//  M3AppDelegate.h
//  Silent Film
//
//  Created by Max Meyers on 4/28/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface M3AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Calling this will delete any files already here.
+ (NSURL*)fileURLForTemporaryFileNamed:(NSString*)filename;

@end
