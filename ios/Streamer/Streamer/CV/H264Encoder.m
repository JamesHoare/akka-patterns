#import "H264Encoder.h"
#import <AVFoundation/AVFoundation.h>

@implementation H264Encoder {
	id<H264EncoderDelegate> delegate;
	
	AVAssetWriter* assetWriter;
	AVAssetWriterInput *assetWriterVideoIn;
	
	dispatch_queue_t videoWritingQueue;
	
	bool recording;
	
	NSURL *videoFileUrl;
	NSFileHandle *videoFileHandle;
}

- (H264Encoder*)initWithDelegate:(id<H264EncoderDelegate>)aDelegate {
	self = [super init];
	if (self) {
		delegate = aDelegate;
		recording = false;
		
		self.width = 1080;
		self.height = 720;

		float bitsPerPixel;
		int numPixels = self.width * self.height;
		
		// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
		if (numPixels < (640 * 480))
			bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
		else
			bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
		
		self.bitsPerSecond = numPixels * bitsPerPixel;
	}
	return self;
}

#pragma mark - AVAssetWriter setup

- (bool)initializeVideoWriter {
	NSError *error;
	
	// setup up temporary file
	videoFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"temp.mp4"]];
	// remove the temp file
	[[NSFileManager defaultManager] removeItemAtURL:videoFileUrl error:&error];
	
	// setup the writer
	assetWriter = [[AVAssetWriter alloc] initWithURL:videoFileUrl fileType:AVFileTypeMPEG4 error:&error];
	
	NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  AVVideoCodecH264, AVVideoCodecKey,
											  [NSNumber numberWithInteger:self.width], AVVideoWidthKey,
											  [NSNumber numberWithInteger:self.height], AVVideoHeightKey,
											  [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInteger:self.bitsPerSecond], AVVideoAverageBitRateKey,
											   [NSNumber numberWithInteger:self.frameRate], AVVideoMaxKeyFrameIntervalKey,
											   [NSNumber numberWithInteger:self.keyFrameInterval], AVVideoMaxKeyFrameIntervalKey,
											   nil], AVVideoCompressionPropertiesKey,
											  nil];
	if ([assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
		assetWriterVideoIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
		assetWriterVideoIn.expectsMediaDataInRealTime = YES;
		// TODO: sort out if we need to do some image transforms
		// assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:self.referenceOrientation];
		if ([assetWriter canAddInput:assetWriterVideoIn])
			[assetWriter addInput:assetWriterVideoIn];
		else {
			NSLog(@"Couldn't add asset writer video input.");
            return false;
		}
	}
	else {
		NSLog(@"Couldn't apply video output settings.");
        return false;
	}
    
    return true;
}

#pragma mark - File handling
- (void)readFromVideoFile {
	NSData *data = [videoFileHandle availableData];
/*
	uint8_t buffer[16384];
	unsigned int len;
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:16384];
	while ((len = [videoFileStream read:buffer maxLength:16384]) > 0) {
		[data appendBytes:buffer length:len];
	}
*/
	if ([data length] > 0) [delegate h264EncoderOnFrame:self completedFrameData:data];
}

#pragma mark - Encoder usage

- (bool)startEncoder {
	videoWritingQueue = dispatch_queue_create("VideoEncodingQueue", NULL);
	dispatch_async(videoWritingQueue, ^{
		if (![self initializeVideoWriter]) return;
		if (recording) return;
	});
	return true;
}

- (bool)stopEncoder {
	dispatch_async(videoWritingQueue, ^{
		if (!recording) return;
		
		[assetWriter finishWritingWithCompletionHandler:^() {
			recording = false;
			
			if (videoFileHandle	!= nil) [videoFileHandle closeFile];
			
			assetWriter = nil;
			assetWriterVideoIn = nil;
			videoFileHandle = nil;
		}];
	});
	return true;
}

- (bool)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	if (assetWriter.status == AVAssetWriterStatusUnknown) {
        if ([assetWriter startWriting]) {
			[assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
			NSError *error;
			videoFileHandle = [NSFileHandle fileHandleForReadingFromURL:videoFileUrl error:&error];
		} else {
			NSLog(@"%@", [assetWriter error]);
			return false;
		}
	}
	
	if (assetWriter.status == AVAssetWriterStatusWriting) {
		if (assetWriterVideoIn.readyForMoreMediaData) {
//			
//			NSError *error;
//			NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[videoFileUrl path] error:&error];
//			NSLog(@"Size %@", [attrs valueForKey:NSFileSize]);
//			
			[self readFromVideoFile];
			if (![assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
				NSLog(@"%@", [assetWriter error]);
				return false;
			}
		}
	}
	return true;
}

@end
