//
//  M3Video.h
//  Silent Film
//
//  Created by Max Meyers on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface M3Video : NSObject

@property UIImage *titleCard;
@property AVAsset *titleCardAsset;
@property AVAsset *video;
@property NSURL *outputURL;

- (void)exportWithCallback:(void (^)())callback;

@end
