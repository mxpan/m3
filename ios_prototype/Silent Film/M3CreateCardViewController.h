//
//  M3CreateCardViewController.h
//  Silent Film
//
//  Created by Matthew Pick on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M3ThreadViewController.h"

@interface M3CreateCardViewController : UIViewController

@property BOOL isTitleCard;
@property (weak) M3ThreadViewController *threadViewController;
@property (readonly) UIImage *image;

@end
