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

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

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
            AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            AVAssetTrack *firstVideoAssetTrack = [[titleCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVAssetTrack *secondVideoAssetTrack = [[self.video tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            
            CGSize finalVideoSize = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);

            CGFloat xScale = finalVideoSize.width / firstVideoAssetTrack.naturalSize.width;
            CGFloat yScale = finalVideoSize.height / firstVideoAssetTrack.naturalSize.height;
            
            CMTime videoSwitch = firstVideoAssetTrack.timeRange.duration;
            
            [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoSwitch) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
            [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:videoSwitch error:nil];
            
            AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            // Set the time range of the first instruction to span the duration of the first video track.
            firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
            AVMutableVideoCompositionInstruction * secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            // Set the time range of the second instruction to span the duration of the second video track.
            secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(firstVideoAssetTrack.timeRange.duration, CMTimeAdd(firstVideoAssetTrack.timeRange.duration, secondVideoAssetTrack.timeRange.duration));
            AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
            // Set the transform of the first layer instruction to the preferred transform of the first video track.
            [firstVideoLayerInstruction setTransform:CGAffineTransformMakeScale(xScale, yScale) atTime:kCMTimeZero];
            AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
            // Set the transform of the second layer instruction to the preferred transform of the second video track.
            
            
            CGAffineTransform rotate = CGAffineTransformMakeRotation(DEGREES_RADIANS(90));
            CGAffineTransform translate = CGAffineTransformMakeTranslation(finalVideoSize.width, 0);
            
            [secondVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:firstVideoAssetTrack.timeRange.duration];
            firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
            secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
            AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
            mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction];

            
            mutableVideoComposition.renderSize = finalVideoSize;
            mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
            exporter.outputURL = self.outputURL;
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
            exporter.videoComposition = mutableVideoComposition;
            
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
