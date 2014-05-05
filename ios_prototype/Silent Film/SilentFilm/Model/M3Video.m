//
//  M3Video.m
//  Silent Film
//
//  Created by Max Meyers on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3Video.h"
#import "M3AssetRenderer.h"
#import "M3AppDelegate.h"

@implementation M3Video

- (void)exportWithCallback:(void (^)())callback
{
    NSParameterAssert(self.video);
    NSParameterAssert(self.titleCard);
    NSParameterAssert(self.outputURL);
    
    [M3AssetRenderer getAssetForTitleCard:self.titleCard withCallback:^(AVAsset *asset) {
        AVAsset *titleCardAsset = asset;
        
        [M3AssetRenderer convertAsset:self.video toLowQualityWithCallback:^(AVAsset *asset) {
            AVMutableComposition *composition = [AVMutableComposition composition];
            AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            videoTrack.preferredTransform = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
            
            AVAssetTrack *firstVideoAssetTrack = [[titleCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVAssetTrack *secondVideoAssetTrack = [[self.video tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            CMTime videoSwitch = firstVideoAssetTrack.timeRange.duration;
            
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoSwitch) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:videoSwitch error:nil];
            
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
            exporter.outputURL = self.outputURL;
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
            
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                NSError *error = exporter.error;
                if (error) {
                    NSLog(@"Failed export: %@", error);
                } else {
                    NSLog(@"Export success: %@", self.outputURL);
                }
                if (callback) {
                    callback();
                }
            }];
        }];
    }];
    
}

@end
