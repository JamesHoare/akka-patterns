#import "ViewController.h"

#define FRAMES_PER_SECOND 5
#define FRAMES_PER_SECOND_MOD (25 / FRAMES_PER_SECOND)

@implementation ViewController {
	id<CVServerConnectionInput> frameInput;
	AVCaptureSession *captureSession;
	AVCaptureVideoPreviewLayer *previewLayer;
	int frameMod;
	
	NSURL *serverUrl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	serverUrl = [NSURL URLWithString:@"http://192.168.200.108:8088/recog/stream"];
	
	// Video capture session; without a device attached to it.
	captureSession = [[AVCaptureSession alloc] init];
	
	// Preview layer that will show the video
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = CGRectMake(0, 100, 320, 640);
	previewLayer.contentsGravity = kCAGravityResizeAspectFill;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer:previewLayer];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)startCapture:(id)sender	{
#if !(TARGET_IPHONE_SIMULATOR)
	// begin the capture
	AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	// video output is the callback
	AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoOutput.alwaysDiscardsLateVideoFrames = YES;
	videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:queue];
	
	// video input is the camera
	AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	
	// capture session connects the input with the output (camera -> self.captureOutput)
	[captureSession addInput:videoInput];
	[captureSession addOutput:videoOutput];
	
	// start the capture session
	[captureSession startRunning];

	// start the connection and grab the CVServerConnectionInput
	frameInput = [[CVServerConnection connectionToStream:serverUrl withDelegate:self] startRunning];
#endif
}

- (IBAction)stopCapture:(id)sender {
	[captureSession stopRunning];
	[frameInput stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
#if !(TARGET_IPHONE_SIMULATOR)
	frameMod++;
	if (frameMod % FRAMES_PER_SECOND_MOD == 0) {
		[frameInput submitFrame:sampleBuffer];
	}
#endif
}

#pragma mark - CVServerConnectionDelegate methods

- (void)cvServerConnectionOk:(id)response {
	NSLog(@":))");
}

- (void)cvServerConnectionAccepted:(id)response {
	NSLog(@":)");
}

- (void)cvServerConnectionRejected:(id)response {
	NSLog(@":(");
}

- (void)cvServerConnectionFailed:(NSError *)reason {
	NSLog(@":((");
}

@end
