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

@interface M3Video ()

    @property AVAsset *titleCardAsset;

@end

@implementation M3Video

- (void)exportWithCallback:(void (^)())callback
{
    NSParameterAssert(self.video);
//    NSParameterAssert(self.titleCard);
    NSParameterAssert(self.outputURL);
    
    if (self.titleCard){
        [M3AssetRenderer getAssetForTitleCard:self.titleCard withIndex:0 withCallback:^(AVAsset *titleCardAsset) {
            self.titleCardAsset = titleCardAsset;
        }];
    }
    
    [self convertVideo:callback];
}

- (void) convertVideo:(void (^)())callback
{
    [M3AssetRenderer convertAsset:self.video toLowQualityWithCallback:^(AVAsset *asset) {
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *firstVideoAssetTrack;
        AVAssetTrack *secondVideoAssetTrack;
        
        if (self.titleCard){
            firstVideoAssetTrack = [[self.titleCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            secondVideoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        } else {
            firstVideoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
       
        //                AVAssetTrack *thirdVideoAssetTrack = [[endCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGSize finalVideoSize;
        
        if (self.titleCard) finalVideoSize = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);
        else finalVideoSize = CGSizeMake(firstVideoAssetTrack.naturalSize.height, firstVideoAssetTrack.naturalSize.width);
        
        CGFloat xScale;
        CGFloat yScale;
        
        if (self.titleCard){
            xScale = finalVideoSize.width / firstVideoAssetTrack.naturalSize.width;
            yScale = finalVideoSize.height / firstVideoAssetTrack.naturalSize.height;
        } else {
            xScale = 1;
            yScale = 1;
        }
        
        CMTime videoSwitch = firstVideoAssetTrack.timeRange.duration;
        //                CMTime endSwitch = CMTimeAdd(videoSwitch, secondVideoAssetTrack.timeRange.duration);
        
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
        
        if (self.titleCard) [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:videoSwitch error:nil];
        //                [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, thirdVideoAssetTrack.timeRange.duration) ofTrack:thirdVideoAssetTrack atTime:endSwitch error:nil];
        
        AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        AVMutableVideoCompositionInstruction *secondVideoCompositionInstruction;
        if (self.titleCard) secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
        if (self.titleCard) secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(videoSwitch, secondVideoAssetTrack.timeRange.duration);
        
        AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction;
        if (self.titleCard) secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        
//        [firstVideoLayerInstruction setTransform:CGAffineTransformMakeScale(xScale, yScale) atTime:kCMTimeZero];
        
        CGAffineTransform rotate = CGAffineTransformMakeRotation(DEGREES_RADIANS(90));
        CGAffineTransform translate = CGAffineTransformMakeTranslation(finalVideoSize.width, 0);
        if (self.titleCard) [secondVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:firstVideoAssetTrack.timeRange.duration];
        else [firstVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:kCMTimeZero];
        
        firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
        if (self.titleCard) secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
        
        AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        if (self.titleCard) mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction];
        else mutableVideoComposition.instructions = @[firstVideoCompositionInstruction];
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
}

@end
