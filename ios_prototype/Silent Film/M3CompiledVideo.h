//
//  M3CompiledVideo.h
//  Silent Film
//
//  Created by Matthew Pick on 5/19/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface M3CompiledVideo : NSObject

@property NSMutableArray *posts;
@property UIImage *endCard;
@property NSURL *outputURL;

- (void)renderFullVideo:(void (^)())callback;

@end
