//
//  M3AssetRenderer.m
//  Silent Film
//
//  Created by Max Meyers on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3AssetRenderer.h"
#import "M3AppDelegate.h"

@implementation M3AssetRenderer

+ (void)getAssetForTitleCard:(UIImage*)titleCard withIndex:(NSInteger)index withCallback:(void (^)(AVAsset *asset))callback
{
    if (!titleCard) {
        callback(nil);
        return;
    }
    NSURL *outputUrl = [M3AppDelegate fileURLForTemporaryFileNamed:[NSString stringWithFormat:@"titlecard-%d.mov", index]];
    [self writeImage:titleCard toMovieAtPath:outputUrl withSize:titleCard.size callback:^{
        if (callback) {
            AVAsset *asset = [AVAsset assetWithURL:outputUrl];
            callback(asset);
        }
    }];
}

+ (void)convertAsset:(AVAsset *)asset toLowQualityWithCallback:(void (^)(AVAsset *asset))callback
{
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    NSURL *tempUrl = [M3AppDelegate fileURLForTemporaryFileNamed:@"lower_quality.mov"];
    exportSession.outputURL = tempUrl;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        AVAsset *lowerQualityAsset = [AVAsset assetWithURL:tempUrl];
        if (callback) {
            callback(lowerQualityAsset);
        }
    }];
}

// Adapted from StackOverflow:
// http://stackoverflow.com/questions/5640657/avfoundation-assetwriter-generate-movie-with-images-and-audio
//

+ (void) writeImage:(UIImage*)image toMovieAtPath:(NSURL *) path withSize:(CGSize)size callback:(void (^)())callback;
{    
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:path fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    
    //convert uiimage to CGImage.
    
    int frameCount = 0;
    
    int framesPerSecond = 1;
    int seconds = 3;

    CGImageRef imageRef = [image CGImage];
    for (int i = 0; i < framesPerSecond*seconds; i++) {
        buffer = [self pixelBufferFromCGImage:imageRef andSize:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
//                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) framesPerSecond);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                [NSThread sleepForTimeInterval:0.001];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        frameCount++;
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Asset Writer finished (%@)", videoWriter);
        if (callback) {
            callback();
        }
    }];
}

+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
