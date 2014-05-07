//
//  M3AssetRenderer.h
//  Silent Film
//
//  Created by Max Meyers on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface M3AssetRenderer : NSObject

+ (void)getAssetForTitleCard:(UIImage*)titleCard withIndex:(NSInteger)index withCallback:(void (^)(AVAsset *asset))callback;
+ (void)convertAsset:(AVAsset *)asset toLowQualityWithCallback:(void (^)(AVAsset *asset))callback;

@end
