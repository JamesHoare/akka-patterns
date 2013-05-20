#import "ViewController.h"

/**
 * ReadBehindFile allows you to read a file that is being written to from another thread. Call ``+initWithURL`` giving the
 * URL of the file that is being written to; then, after having created a ``dispatch_queue_t``, call the ``-start`` method.
 * When you want to stop reading, call the ``-stop`` method.
 */
typedef void (^BlockCallback)(uint8_t* data, unsigned int size);

@interface ReadBehindFile : NSObject <NSStreamDelegate> {
	NSURL* _file;
	bool _stop;
	BlockCallback _block;
	dispatch_queue_t queue;
}
+ (ReadBehindFile*)initWithURL:(NSURL*)file;
- (void)start:(BlockCallback)block;
- (void)stop;
@end

@implementation ReadBehindFile

+ (ReadBehindFile*)initWithURL:(NSURL *)file {
	ReadBehindFile* instance = [[ReadBehindFile alloc] init];
	instance->_file = file;
	return instance;
}

- (void)start:(BlockCallback)block {
	queue = dispatch_queue_create("ReadBehindFile", NULL);
	_stop = false;
	_block = block;
//	dispatch_async(queue, ^ {
		NSInputStream *stream = [NSInputStream inputStreamWithURL:_file];
		[stream setDelegate:self];
		[stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[stream open];
//		uint8_t buffer[65536];
//		while (!stop) {
//			NSUInteger read = [stream read:buffer maxLength:65536];
//			if (read > 0) block(buffer, read);
//			sleep(1);
//		}
//		[stream close];
//	});
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	NSInputStream *is = (NSInputStream *)aStream;
	switch (eventCode) {
		case NSStreamEventHasBytesAvailable: {
			#define BUFFER_SIZE 65536
			uint8_t buffer[BUFFER_SIZE];
			NSUInteger len = [is read:buffer maxLength:BUFFER_SIZE];
			if (len > 0) _block(buffer, len);
			break;
		}
		default:
			return;
	}
}

- (void)stop {
	_stop = true;
}

@end


@interface ViewController () {
	NSURL *videoFileUrl;
	ReadBehindFile* readBehindFile;
	int count;
	
	AVCaptureDevice *captureDevice;
	AVCaptureSession *captureSession;
	AVCaptureVideoDataOutput *videoOutput;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVAssetWriter *videoWriter;
	AVAssetWriterInput *videoWriterInput;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Where the video goes to
	videoFileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"face.mov"]];
	[[NSFileManager defaultManager] removeItemAtURL:videoFileUrl error:nil];
	
	readBehindFile = [ReadBehindFile initWithURL:videoFileUrl];
	
	// Video capture session; without a device attached to it.
	captureSession = [[AVCaptureSession alloc] init];
	
	// Preview layer that will show the video
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = self.view.bounds;
	previewLayer.contentsGravity = kCAGravityResizeAspectFill;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer:previewLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if(!CMSampleBufferDataIsReady(sampleBuffer)) {
		NSLog( @"sample buffer is not ready. Skipping sample" );
		return;
	}
	
	if (videoWriter.status != AVAssetWriterStatusWriting) {
		CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
		if (![videoWriter startWriting]) NSLog(@"Could not start writing");
		[videoWriter startSessionAtSourceTime:lastSampleTime];
	}
		
	[self newVideoSample:sampleBuffer];
}

- (void)newVideoSample:(CMSampleBufferRef)sampleBuffer {
	count++;
	if (count > 100) {
		[videoWriter finishWritingWithCompletionHandler:^() {}];
	}
	if (videoWriter.status > AVAssetWriterStatusWriting) {
		NSLog(@"Warning: writer status is %d", videoWriter.status);
		if (videoWriter.status == AVAssetWriterStatusFailed) {
			NSLog(@"Error: %@", videoWriter.error);
			return;
		}
	}
	if (![videoWriterInput appendSampleBuffer:sampleBuffer]) NSLog(@"Unable to write to video input");
	NSError *error;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[videoFileUrl path] error:&error];
	NSLog(@"Written %lld", [fileAttributes fileSize]);
}

- (IBAction)startCapture:(id)sender {
	AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	// video output is the callback
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoOutput.alwaysDiscardsLateVideoFrames = YES;
	videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];

	// video input is the camera
	videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	
	// capture session connects the input with the output (camera -> self.captureOutput)
	[captureSession addInput:videoInput];
	[captureSession addOutput:videoOutput];
		
	// Video compression settings & video writer input
	NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:128.0 * 1024.0], AVVideoAverageBitRateKey,
										   nil];
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:1080], AVVideoWidthKey,
								   [NSNumber numberWithInt:720], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	videoWriterInput.expectsMediaDataInRealTime = YES;

	// writer will write the video to the given file
	videoWriter = [[AVAssetWriter alloc] initWithURL:videoFileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
	videoWriter.shouldOptimizeForNetworkUse = true;
	[videoWriter addInput:videoWriterInput];

	// start the capture session
	[captureSession startRunning];
	//[readBehindFile start:^(uint8_t *data, unsigned int size) { NSLog(@"Read %d bytes", size); }];
}

@end
