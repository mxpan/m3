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

@end

@implementation M3Video

- (void)exportWithCallback:(void (^)())callback
{
    NSParameterAssert(self.video);
//    NSParameterAssert(self.titleCard);
    NSParameterAssert(self.outputURL);
    
    if (self.titleCard){
        [M3AssetRenderer getAssetForTitleCard:self.titleCard withIndex:0 withCallback:^(AVAsset *titleCardAsset, NSURL *url) {
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
        AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *firstVideoAssetTrack;
        AVAssetTrack *secondVideoAssetTrack;
//        AVAssetTrack *audioTrack;
        
        if (self.titleCardAsset){
            firstVideoAssetTrack = [[self.titleCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            secondVideoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        } else {
            firstVideoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
//        audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        CGSize finalVideoSize;
        
        if (self.titleCardAsset) finalVideoSize = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);
        else finalVideoSize = CGSizeMake(firstVideoAssetTrack.naturalSize.height, firstVideoAssetTrack.naturalSize.width);
        
        CGFloat xScale;
        CGFloat yScale;
        
        if (self.titleCardAsset){
            xScale = finalVideoSize.width / firstVideoAssetTrack.naturalSize.width;
            yScale = finalVideoSize.height / firstVideoAssetTrack.naturalSize.height;
        } else {
            xScale = 1;
            yScale = 1;
        }
        
        CMTime videoSwitch = firstVideoAssetTrack.timeRange.duration;
        
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
        
        if (self.titleCardAsset) {
            [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:videoSwitch error:nil];
//            [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTrack.timeRange.duration) ofTrack:audioTrack atTime:videoSwitch error:nil];
        } else {
//            [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTrack.timeRange.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        }
    
        
        AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        AVMutableVideoCompositionInstruction *secondVideoCompositionInstruction;
        if (self.titleCardAsset) secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
        if (self.titleCardAsset) secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(videoSwitch, secondVideoAssetTrack.timeRange.duration);
        
        AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction;
        if (self.titleCardAsset) secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        
        
        CGAffineTransform rotate = CGAffineTransformMakeRotation(DEGREES_RADIANS(90));
        CGAffineTransform translate = CGAffineTransformMakeTranslation(finalVideoSize.width, 0);
        if (self.titleCardAsset) {
            [secondVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:firstVideoAssetTrack.timeRange.duration];
        } else {
            [firstVideoLayerInstruction setTransform:CGAffineTransformConcat(rotate, translate) atTime:kCMTimeZero];
        }
        
        firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
        if (self.titleCardAsset) secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
        
        AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        if (self.titleCardAsset) mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction];
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
