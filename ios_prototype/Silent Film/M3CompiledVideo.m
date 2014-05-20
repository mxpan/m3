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

@implementation M3CompiledVideo

- (void)renderFullVideo:(void (^)())callback
{
//    NSParameterAssert(self.video);
    //    NSParameterAssert(self.titleCard);
    NSParameterAssert(self.outputURL);
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    NSMutableArray *mutableCompositionInstructionsArr = [[NSMutableArray alloc] init];
   
    CMTime startTime = kCMTimeZero;
    
    CGSize finalVideoSize;
    CGFloat xScale;
    CGFloat yScale;
    
    
    for (int i=0; i<self.posts.count; i++){
        M3Post *post = [self.posts objectAtIndex:i];
//        NSURL *vidURL = [M3AppDelegate fileURLForTemporaryFileNamed:[NSString stringWithFormat:@"video%i.mov", i]];
        NSURL *vidURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"video%i.mov", i]]];
        NSError *error;
        bool success = [[post.video getData] writeToURL:vidURL options:0 error:&error];
//        success = [plistData writeToFile:file options:0 error:&error];
        if (!success) {
            NSLog(@"writeToFile failed with error %@", [error localizedDescription]);
        }

        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:vidURL options:nil];
        AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        
        if (i==0){
            finalVideoSize = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.width);
            xScale = finalVideoSize.width / assetTrack.naturalSize.width;
            yScale = finalVideoSize.height / assetTrack.naturalSize.height;
        }
        
        
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetTrack.timeRange.duration) ofTrack:assetTrack atTime:startTime error:nil];
        
        AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        inst.timeRange = CMTimeRangeMake(startTime, assetTrack.timeRange.duration);
        
        AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        
        inst.layerInstructions = @[layerInst];
        
        [mutableCompositionInstructionsArr insertObject:inst atIndex:mutableCompositionInstructionsArr.count];
        
        startTime = CMTimeAdd(startTime, assetTrack.timeRange.duration);
    }
    
    mutableVideoComposition.instructions = [[NSArray alloc] initWithArray:mutableCompositionInstructionsArr];
    
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
}

@end
