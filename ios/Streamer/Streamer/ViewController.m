#import "ViewController.h"

/**
 * ReadBehindFile allows you to read a file that is being written to from another thread. Call ``+initWithURL`` giving the
 * URL of the file that is being written to; then, after having created a ``dispatch_queue_t``, call the ``-start`` method.
 * When you want to stop reading, call the ``-stop`` method.
 */
typedef void (^BlockCallback)(uint8_t* data, unsigned int size);

@interface ReadBehindFile : NSObject {
	NSURL* file;
	bool stop;
	dispatch_queue_t queue;
}
+ (ReadBehindFile*)initWithURL:(NSURL*)file;
- (void)start:(BlockCallback)block;
- (void)stop;
@end

@implementation ReadBehindFile

+ (ReadBehindFile*)initWithURL:(NSURL *)file {
	ReadBehindFile* instance = [[ReadBehindFile alloc] init];
	instance->file = file;
	return instance;
}

- (void)start:(BlockCallback)block {
	queue = dispatch_queue_create("ReadBehindFile", NULL);
	stop = false;
	dispatch_async(queue, ^ {
		NSInputStream *stream = [NSInputStream inputStreamWithURL:file];
		uint8_t buffer[65536];
		while (!stop) {
			NSUInteger read = [stream read:buffer maxLength:65536];
			if (read > 0) block(buffer, read);
			sleep(1);
		}
		[stream close];
	});
}

- (void)stop {
	stop = true;
}

@end


@interface ViewController () {
	NSURL *videoFileUrl;
	ReadBehindFile* readBehindFile;
	
	AVCaptureDevice *captureDevice;
	AVCaptureSession *captureSession;
	AVCaptureVideoDataOutput *videoOutput;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVAssetWriter *videoWriter;
	AVAssetWriterInput *videoWriterInput;
	CMTime lastSampleTime;
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
	
	lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	if (videoWriter.status != AVAssetWriterStatusWriting) {
		[videoWriter startWriting];
		[videoWriter startSessionAtSourceTime:lastSampleTime];
	}
		
	[self newVideoSample:sampleBuffer];
}

- (void)newVideoSample:(CMSampleBufferRef)sampleBuffer {
	if (videoWriter.status > AVAssetWriterStatusWriting) {
		NSLog(@"Warning: writer status is %d", videoWriter.status);
		if (videoWriter.status == AVAssetWriterStatusFailed) {
			NSLog(@"Error: %@", videoWriter.error);
			return;
		}
		
		if (![videoWriterInput appendSampleBuffer:sampleBuffer]) NSLog(@"Unable to write to video input");
	}
	
}

- (IBAction)startCapture:(id)sender {
	AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoOutput.alwaysDiscardsLateVideoFrames = YES;
	videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];

	videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	[captureSession addInput:videoInput];
	[captureSession addOutput:videoOutput];
	dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
	
	// Video compression settings
	NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:128.0*1024.0], AVVideoAverageBitRateKey,
										   nil ];
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:192], AVVideoWidthKey,
								   [NSNumber numberWithInt:144], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];

	videoWriter = [[AVAssetWriter alloc] initWithURL:videoFileUrl fileType:AVFileTypeQuickTimeMovie error:&error];
	videoWriter.shouldOptimizeForNetworkUse = true;
	videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	[videoWriter addInput:videoWriterInput];

	[captureSession startRunning];
	[readBehindFile start:^(uint8_t *data, unsigned int size) { NSLog(@"Read %d bytes", size); }];
}

@end
