#import "H264Encoder.h"
#import <AVFoundation/AVFoundation.h>

@implementation H264Encoder {
	id<H264EncoderDelegate> delegate;
	
	AVAssetWriter* assetWriter;
	AVAssetWriterInput *assetWriterVideoIn;
	AVAssetWriterInputPixelBufferAdaptor *assetWriterInputAdaptor;

	dispatch_semaphore_t moovSemaphore;
	
	bool recording;
	
	NSURL *videoFileUrl;
	NSFileHandle *videoFileHandle;
	unsigned long videoFileSize;
	unsigned long bytesToDrop;
}

- (H264Encoder*)initWithDelegate:(id<H264EncoderDelegate>)aDelegate {
	self = [super init];
	if (self) {
		delegate = aDelegate;
		recording = false;
		moovSemaphore = dispatch_semaphore_create(0);
		
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

- (bool)initializeVideoWriter:(bool)optimizeForNetworkUse {
	NSError *error;
	
	// setup up temporary file
	videoFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"temp.mp4"]];
	// remove the temp file
	[[NSFileManager defaultManager] removeItemAtURL:videoFileUrl error:&error];
	
	// setup the writer
	assetWriter = [[AVAssetWriter alloc] initWithURL:videoFileUrl fileType:AVFileTypeMPEG4 error:&error];
	assetWriter.shouldOptimizeForNetworkUse = optimizeForNetworkUse;
	
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
	NSError *error;
	NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[videoFileUrl path] error:&error];
	NSLog(@"Size %@", [attrs valueForKey:NSFileSize]);

	NSData *data = [videoFileHandle availableData];
	if (data.length > 0) {
		if (bytesToDrop > 0 && data.length > bytesToDrop) {
			NSData *realData = [data subdataWithRange:NSMakeRange(bytesToDrop, data.length - bytesToDrop)];
			bytesToDrop = 0;
			[delegate h264EncoderOnFrame:self completedFrameData:realData];
		} else {
			[delegate h264EncoderOnFrame:self completedFrameData:data];
		}
	}
	videoFileSize += data.length;
}

#pragma mark - Encoder usage

- (void)encodeEmptyFrame {
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
	CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, self.width, self.height,
                        kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options,
                        &pixelBuffer);
		
	for (int i = 0; i < 10; i++) {
		if (assetWriterInputAdaptor.assetWriterInput.readyForMoreMediaData) {
			if (![assetWriterInputAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(i, 1)]) {
				NSLog(@"%@", [assetWriter error]);
			} else {
				NSLog(@"Written.");
			}
		} else {
			NSLog(@"Not ready.");
		}
		usleep(25000);	// 25ms
	}
		
	CVPixelBufferRelease(pixelBuffer);
}

- (bool)stopVideoWriter {
	if (!recording) return false;
	[assetWriter finishWritingWithCompletionHandler:^() {
		recording = false;

		[self readFromVideoFile];
		if (videoFileHandle	!= nil) [videoFileHandle closeFile];
		
		assetWriter = nil;
		assetWriterVideoIn = nil;
		videoFileHandle = nil;
		
		dispatch_semaphore_signal(moovSemaphore);
	}];
	dispatch_semaphore_wait(moovSemaphore, DISPATCH_TIME_FOREVER);

	return true;
}

- (bool)startVideoWriter {
	if (recording) return false;
	
	recording = true;
	if (assetWriter.status == AVAssetWriterStatusUnknown) {
        if ([assetWriter startWriting]) {
			[assetWriter startSessionAtSourceTime:CMTimeMake(0, 1)];
			NSError *error;
			videoFileHandle = [NSFileHandle fileHandleForReadingFromURL:videoFileUrl error:&error];
		} else {
			NSLog(@"%@", [assetWriter error]);
			return false;
		}
	}
	return true;
}

- (bool)startEncoder {
	// write the header with one frame
	if (![self initializeVideoWriter:true]) return false;
	NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
														   [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
	assetWriterInputAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:assetWriterVideoIn sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];

	bytesToDrop = 0;
	videoFileSize = 0;
	[self startVideoWriter];
	[self encodeEmptyFrame];
	[self stopVideoWriter];
	bytesToDrop = videoFileSize;
	
	if (![self initializeVideoWriter:false]) return false;
	if (![self startVideoWriter]) return false;
	
	return true;
}

- (bool)stopEncoder {
//	[self stopVideoWriter];
	return true;
}

- (bool)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	if (assetWriter.status == AVAssetWriterStatusWriting) {
		if (assetWriterVideoIn.readyForMoreMediaData) {
			if (![assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
				NSLog(@"%@", [assetWriter error]);
				return false;
			}
			[self readFromVideoFile];
		}
	}
	return true;
}

@end
