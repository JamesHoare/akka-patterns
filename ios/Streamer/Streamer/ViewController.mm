#import "ViewController.h"
#include "AFNetworking/AFHTTPRequestOperation.h"
#include "AFNetworking/AFHTTPClient.h"
#include "QueueStream.h"

@interface ViewController () {
	i264Encoder* encoder;

	AVCaptureDevice *captureDevice;
	AVCaptureSession *captureSession;
	AVCaptureVideoDataOutput *videoOutput;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoPreviewLayer *previewLayer;
	
	NSURL *serverUrl;
	QueueStream *queueStream;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	serverUrl = [NSURL URLWithString:@"http://192.168.200.108:8088/recog/stream"];
	
	// Video capture session; without a device attached to it.
	captureSession = [[AVCaptureSession alloc] init];
	
	// Preview layer that will show the video
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = self.view.bounds;
	previewLayer.contentsGravity = kCAGravityResizeAspectFill;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer:previewLayer];

	// encoder
	encoder = [[i264Encoder alloc] initWithDelegate:self];
	[encoder setInPicHeight:[NSNumber numberWithInt:720]];
	[encoder setInPicWidth:[NSNumber numberWithInt:1080]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)startCapture:(id)sender	{
	AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	queueStream = [[QueueStream alloc] init];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverUrl];
	[request setTimeoutInterval:5.0];
	AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setInputStream:queueStream];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@":)");
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@":(");
	}];
	[operation start];
	[operation waitUntilFinished];
	 
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
	
	// start the capture session
	[encoder startEncoder];
	[captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	[encoder encodePixelBuffer:pixelBuffer];
}

- (void)oni264Encoder:(i264Encoder *)encoder completedFrameData:(NSData *)data {
	[queueStream appendData:data];
}

@end
