//
//  M3CompiledVideo.m
//  Silent Film
//
//  Created by Matthew Pick on 5/19/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3CompiledVideo.h"
#import "M3Post.h"
#import "M3AssetRenderer.h"
#import "M3AppDelegate.h"

@interface M3CompiledVideo ()

@property AVAssetTrack *endCardAssetTrack;

@end

@implementation M3CompiledVideo

- (void)renderFullVideo:(void (^)())callback
{
//    NSParameterAssert(self.video);
    //    NSParameterAssert(self.titleCard);
    NSParameterAssert(self.outputURL);
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSMutableArray *mutableCompositionInstructionsArr = [[NSMutableArray alloc] init];
   
    CMTime startTime = kCMTimeZero;
    
    CGSize finalVideoSize;
    CGFloat xScale;
    CGFloat yScale;
    
    if (self.posts.count > 0){
        
        [self sortPostArray:self.posts];
        
        for (int i=0; i<self.posts.count; i++){
            M3Post *post = [self.posts objectAtIndex:i];

            NSURL *vidURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"video%i.mov", i]]];
            NSError *error;
            bool success = [[[post video] getData] writeToURL:vidURL options:0 error:&error];

            if (!success) {
                NSLog(@"writeToFile failed with error %@", [error localizedDescription]);
            }

            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:vidURL options:nil];
            AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            
            if (i==0){
                finalVideoSize = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.width);
                xScale = finalVideoSize.width / assetTrack.naturalSize.width;
                yScale = finalVideoSize.height / assetTrack.naturalSize.height;
            }
            
            
            [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrack.timeRange.duration) ofTrack:assetTrack atTime:startTime error:nil];
            [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTrack.timeRange.duration) ofTrack:audioTrack atTime:startTime error:nil];
            
            AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            inst.timeRange = CMTimeRangeMake(startTime, assetTrack.timeRange.duration);
            
            AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
            
            inst.layerInstructions = @[layerInst];
            
            [mutableCompositionInstructionsArr insertObject:inst atIndex:mutableCompositionInstructionsArr.count];
            
            startTime = CMTimeAdd(startTime, assetTrack.timeRange.duration);
        }
        
        if (self.endCard){
            [M3AssetRenderer getAssetForTitleCard:self.endCard withIndex:0 withCallback:^(AVAsset *endCardAsset) {
                self.endCardAssetTrack = [[endCardAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
                [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.endCardAssetTrack.timeRange.duration) ofTrack:self.endCardAssetTrack atTime:startTime error:nil];
                
                
                AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
                inst.timeRange = CMTimeRangeMake(startTime, self.endCardAssetTrack.timeRange.duration);
                
                AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
                
                inst.layerInstructions = @[layerInst];
                
                [mutableCompositionInstructionsArr insertObject:inst atIndex:mutableCompositionInstructionsArr.count];
                [self exportMovie:callback withComposition:composition];
            }];
        } else {
            [self exportMovie:callback withComposition:composition];
        }
    }
}

- (void) exportMovie:(void (^)())callback withComposition:(AVMutableComposition *)composition{
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
}

- (void) sortPostArray:(NSMutableArray*)arr {
    [arr sortUsingComparator:^NSComparisonResult(id a, id b) {
        NSDate *first = [(M3Post*)a createdAt];
        NSDate *second = [(M3Post*)b createdAt];
        return [first compare:second];
    }];
}

@end
