//
//  M3StartViewController.h
//  Silent Film
//
//  Created by Max Meyers on 5/27/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface M3StartViewController : UIViewController

@property (nonatomic, copy) void (^callback)();
- (void)start;

@end
