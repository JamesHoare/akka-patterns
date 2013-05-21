#import "ViewController.h"
#include "AFNetworking/AFHTTPRequestOperation.h"
#include "AFNetworking/AFHTTPClient.h"
#include "NSStream+Bound.h"

@implementation ViewController {
#if !(TARGET_IPHONE_SIMULATOR)
	i264Encoder* encoder;
#endif
	AVCaptureDevice *captureDevice;
	AVCaptureSession *captureSession;
	AVCaptureVideoDataOutput *videoOutput;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoPreviewLayer *previewLayer;
	
	NSURL *serverUrl;
	NSOutputStream *videoStream;
	NSInputStream *postStream;
}

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

#if !(TARGET_IPHONE_SIMULATOR)
	// encoder
	encoder = [[i264Encoder alloc] initWithDelegate:self];
	[encoder setInPicHeight:[NSNumber numberWithInt:720]];
	[encoder setInPicWidth:[NSNumber numberWithInt:1080]];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)startCapture:(id)sender	{
	[NSStream createBoundInputStream:&postStream outputStream:&videoStream bufferSize:16384];
	
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverUrl];
	[request setTimeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	HSRandomDataInputStream *is = [[HSRandomDataInputStream alloc] init]; //[NSInputStream inputStreamWithData:[@"foadfsdfsafdd" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBodyStream:is];
	[request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@":)");
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@":( %@", error);
	}];
	[operation start];
	
	[is setData:[@"A" dataUsingEncoding:NSUTF8StringEncoding]];
	sleep(1);
	[is setData:[@"B" dataUsingEncoding:NSUTF8StringEncoding]];
	sleep(1);
	[is setData:[@"C" dataUsingEncoding:NSUTF8StringEncoding]];
	sleep(1);
	[is setData:[@"D" dataUsingEncoding:NSUTF8StringEncoding]];


#if !(TARGET_IPHONE_SIMULATOR)
	// begin the capture
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
	
	// start the capture session
	[encoder startEncoder];
	[captureSession startRunning];
#endif
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
#if !(TARGET_IPHONE_SIMULATOR)
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	[encoder encodePixelBuffer:pixelBuffer];
#endif
}

- (void)oni264Encoder:(i264Encoder *)encoder completedFrameData:(NSData *)data {
	uint8_t* buffer = (uint8_t*)[data bytes];
	[videoStream write:buffer maxLength:[data length]];
}

@end
