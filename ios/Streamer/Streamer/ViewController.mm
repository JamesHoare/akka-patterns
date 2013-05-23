#import "ViewController.h"

#define FRAMES_PER_SECOND 5
#define FRAMES_PER_SECOND_MOD (25 / FRAMES_PER_SECOND)

@implementation ViewController {
	CVServerConnection *serverConnection;
	CVServerTransactionConnection *serverTransactionConnection;
	id<CVServerConnectionInput> frameInput;
	
	AVCaptureSession *captureSession;
	AVCaptureVideoPreviewLayer *previewLayer;
	int frameMod;
	
	bool capturing;
}

#pragma mark - Housekeeping

- (void)viewDidLoad {
    [super viewDidLoad];
	capturing = false;
	NSURL *serverBaseUrl = [NSURL URLWithString:@"http://192.168.200.108:8088/recog"];
	serverConnection = [CVServerConnection connection:serverBaseUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Video capture (using the back camera)

- (void)startCapture {
#if !(TARGET_IPHONE_SIMULATOR)
	// Video capture session; without a device attached to it.
	captureSession = [[AVCaptureSession alloc] init];
	
	// Preview layer that will show the video
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = CGRectMake(0, 100, 320, 640);
	previewLayer.contentsGravity = kCAGravityResizeAspectFill;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer:previewLayer];
	
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
	
	// begin a transaction
	serverTransactionConnection = [serverConnection begin:nil];
	frameInput = [serverTransactionConnection streamInput:self];
#endif
}

- (void)stopCapture {
#if !(TARGET_IPHONE_SIMULATOR)
	[captureSession stopRunning];
	[frameInput stopRunning];
	
	[previewLayer removeFromSuperlayer];
	
	previewLayer = nil;
	captureSession = nil;
	frameInput = nil;
	serverTransactionConnection = nil;
#endif
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
#if !(TARGET_IPHONE_SIMULATOR)
	frameMod++;
	if (frameMod % FRAMES_PER_SECOND_MOD == 0) {
		[frameInput submitFrame:sampleBuffer];
	}
#endif
}

#pragma mark - UI

- (IBAction)startStop:(id)sender {
	if (capturing) {
		[self stopCapture];
		[self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self.startStopButton setTintColor:[UIColor greenColor]];
		capturing = false;
	} else {
		[self startCapture];
		[self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self.startStopButton setTintColor:[UIColor redColor]];
		capturing = true;
	}
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
