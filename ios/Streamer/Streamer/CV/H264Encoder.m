#import "H264Encoder.h"
#import <AVFoundation/AVFoundation.h>

@implementation H264Encoder {
	id<H264EncoderDelegate> delegate;
	
	AVAssetWriter* assetWriter;
	AVAssetWriterInput *assetWriterVideoIn;
	
	dispatch_queue_t videoWritingQueue;
	NSURL *tempVideoFile;
}

- (H264Encoder*)initWithDelegate:(id<H264EncoderDelegate>)aDelegate {
	self = [super init];
	if (self) {
		delegate = aDelegate;
		
		self.width = 1080;
		self.height = 720;
		
	}
	return self;
}

#pragma mark - AVAssetWriter setup

- (BOOL)setupAssetWriter {
	NSError *error;
	
	// setup up temporary file
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mp4"];
	tempVideoFile = [NSURL URLWithString:filePath];
	// remove the temp file
	[[NSFileManager defaultManager] removeItemAtURL:tempVideoFile error:&error];

	// setup the writer
	assetWriter = [[AVAssetWriter alloc] initWithURL:tempVideoFile fileType:AVFileTypeMPEG4 error:&error];

	float bitsPerPixel;
	int numPixels = self.width * self.height;
	int bitsPerSecond;
	
	// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
	if (numPixels < (640 * 480))
		bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
	else
		bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
	
	bitsPerSecond = numPixels * bitsPerPixel;
	
	NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  AVVideoCodecH264, AVVideoCodecKey,
											  [NSNumber numberWithInteger:self.width], AVVideoWidthKey,
											  [NSNumber numberWithInteger:self.height], AVVideoHeightKey,
											  [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
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
            return NO;
		}
	}
	else {
		NSLog(@"Couldn't apply video output settings.");
        return NO;
	}
    
    return YES;
}


#pragma mark - Encoder usage

- (BOOL)startEncoder {
	[self setupAssetWriter];
	return YES;
}

- (BOOL)stopEncoder {
	[assetWriter finishWritingWithCompletionHandler:^() {}];
	return YES;
}

- (BOOL)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer {
	return YES;
}

@end
