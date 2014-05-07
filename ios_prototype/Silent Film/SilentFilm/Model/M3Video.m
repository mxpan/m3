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
    
    [M3AssetRenderer getAssetForTitleCard:self.titleCard withIndex:0 withCallback:^(AVAsset *titleCardAsset) {
        
        [M3AssetRenderer getAssetForTitleCard:self.endCard withIndex:1 withCallback:^(AVAsset *endCardAsset) {
            
            [M3AssetRenderer convertAsset:self.video toLowQualityWithCallback:^(AVAsset *asset) {
                AVMutableComposition *composition = [AVMutableComposition composition];
                AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                
                AVAssetTrack *firstVideoAssetTrack = [[titleCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                AVAssetTrack *secondVideoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                AVAssetTrack *thirdVideoAssetTrack = [[endCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                
                CGSize finalVideoSize = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);
                
                CGFloat xScale = finalVideoSize.width / firstVideoAssetTrack.naturalSize.width;
                CGFloat yScale = finalVideoSize.height / firstVideoAssetTrack.naturalSize.height;
                
                CMTime videoSwitch = firstVideoAssetTrack.timeRange.duration;
                CMTime endSwitch = CMTimeAdd(videoSwitch, secondVideoAssetTrack.timeRange.duration);
                
                [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
                [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:videoSwitch error:nil];
                [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, thirdVideoAssetTrack.timeRange.duration) ofTrack:thirdVideoAssetTrack atTime:endSwitch error:nil];
                
                AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
                AVMutableVideoCompositionInstruction * secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
                AVMutableVideoCompositionInstruction * thirdVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

                firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
                secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(videoSwitch, secondVideoAssetTrack.timeRange.duration);
                thirdVideoCompositionInstruction.timeRange = CMTimeRangeMake(endSwitch, thirdVideoAssetTrack.timeRange.duration);
                
                AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
                AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
                AVMutableVideoCompositionLayerInstruction *thirdVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];

                [firstVideoLayerInstruction setTransform:CGAffineTransformMakeScale(xScale, yScale) atTime:kCMTimeZero];
                [thirdVideoLayerInstruction setTransform:CGAffineTransformMakeScale(xScale, yScale) atTime:kCMTimeZero];
                
                CGAffineTransform rotate = CGAffineTransformMakeRotation(DEGREES_RADIANS(90));
                CGAffineTransform translate = CGAffineTransformMakeTranslation(finalVideoSize.width, 0);
                [secondVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:firstVideoAssetTrack.timeRange.duration];
                
                firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
                secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
                thirdVideoCompositionInstruction.layerInstructions = @[thirdVideoLayerInstruction];
                
                AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
                mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction, thirdVideoCompositionInstruction];
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
        

    }];
    
}

@end
