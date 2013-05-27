#import "CVServer.h"
#import "BlockingQueueInputStream.h"
#import "AFNetworking/AFHTTPRequestOperation.h"
#import "AFNetworking/AFHTTPClient.h"
#import "H264/H264Encoder.h"
#import "H264/VideoEncoder.h"
#import "ImageEncoder.h"

@interface AbstractCVServerConnectionInput : NSObject {
@protected
	NSURL *url;
	NSString *sessionId;
	id<CVServerConnectionDelegate> delegate;
}
- (id)initWithUrl:(NSURL*)url session:(NSString*)session andDelegate:(id<CVServerConnectionDelegate>)delegate;
- (void)initConnectionInput;
@end

@interface CVServerConnectionInputStatic : AbstractCVServerConnectionInput<CVServerConnectionInput>
@end

@interface CVServerConnectionInputStream : AbstractCVServerConnectionInput<CVServerConnectionInput, H264EncoderDelegate> {
#if !(TARGET_IPHONE_SIMULATOR)
	H264Encoder* encoder;
#endif
}
@end

@implementation CVServerTransactionConnection {
	NSURL *baseUrl;
	NSString *sessionId;
}

- (CVServerTransactionConnection*)initWithUrl:(NSURL*)aBaseUrl andSessionId:(NSString*)aSessionId {
	self = [super init];
	if (self) {
		baseUrl = aBaseUrl;
		sessionId = aSessionId;
	}
	return self;
}

- (NSURL*)inputUrl:(NSString*)path {
	NSString *pathWithSessionId = [NSString stringWithFormat:@"%@/%@", path, sessionId];
	return [baseUrl URLByAppendingPathComponent:pathWithSessionId];
}

- (id<CVServerConnectionInput>)staticInput:(id<CVServerConnectionDelegate>)delegate {
	return [[CVServerConnectionInputStatic alloc] initWithUrl:[self inputUrl:@"static"] session:sessionId andDelegate:delegate];
}

- (id<CVServerConnectionInput>)streamInput:(id<CVServerConnectionDelegate>)delegate {
	return [[CVServerConnectionInputStream alloc] initWithUrl:[self inputUrl:@"stream"] session:sessionId andDelegate:delegate];
}

@end

@implementation CVServerConnection {
	NSURL *baseUrl;
}

- (id)initWithUrl:(NSURL *)aBaseUrl {
	self = [super init];
	if (self) {
		baseUrl = aBaseUrl;
	}
	
	return self;
}

+ (CVServerConnection*)connection:(NSURL *)baseUrl {
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	
	return [[CVServerConnection alloc] initWithUrl:baseUrl];
}

- (CVServerTransactionConnection*)begin:(id)configuration {
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseUrl];
	[request setTimeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation start];
	[operation waitUntilFinished];
	NSString* sessionId = [operation responseString];
	return [[CVServerTransactionConnection alloc] initWithUrl:baseUrl andSessionId:sessionId];
}

@end

@implementation AbstractCVServerConnectionInput

- (id)initWithUrl:(NSURL*)aUrl session:(NSString*)aSessionId andDelegate:(id<CVServerConnectionDelegate>)aDelegate {
	self = [super init];
	if (self) {
		url = aUrl;
		sessionId = aSessionId;
		delegate = aDelegate;
		[self initConnectionInput];
	}
	return self;
}

- (void)initConnectionInput {
	// nothing in the abstract class
}

@end

/**
 * Uses plain JPEG encoding to submit the images from the incoming stream of frames
 */
@implementation CVServerConnectionInputStatic {
	ImageEncoder *imageEncoder;
	
}

- (void)initConnectionInput {
	imageEncoder = [[ImageEncoder alloc] init];
}

- (void)submitFrame:(CMSampleBufferRef)frame {
	[imageEncoder encode:frame withSuccess:^(NSData* data) {
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[request setTimeoutInterval:30.0];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:data];
		[request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
		AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
		[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
			[delegate cvServerConnectionOk:responseObject];
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[delegate cvServerConnectionFailed:error];
		}];
		[operation start];
		[operation waitUntilFinished];
	}];
}

- (void)stopRunning {
	// This is a static connection. Nothing to see here.
}

@end

/**
 * Uses the i264 encoder to encode the incoming stream of frames. 
 */
@implementation CVServerConnectionInputStream {
	BlockingQueueInputStream *stream;
}

- (void)initConnectionInput {
	stream = [[BlockingQueueInputStream alloc] init];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setTimeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBodyStream:stream];
	[request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		[delegate cvServerConnectionOk:responseObject];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[delegate cvServerConnectionFailed:error];
	}];
	[operation start];
	
#if !(TARGET_IPHONE_SIMULATOR)
	int framesPerSecond = 25;
	encoder = [[H264Encoder alloc] initWithDelegate:self];
	encoder.height = 480;
	encoder.width = 720;
	encoder.frameRate = framesPerSecond;
	encoder.keyFrameInterval = framesPerSecond * 5;
	encoder.bitsPerSecond = 300000;
	[encoder startEncoder];
#endif
}

- (void)submitFrame:(CMSampleBufferRef)frame {
#if !(TARGET_IPHONE_SIMULATOR)
	[encoder encodeSampleBuffer:frame];
#endif
}

- (void)h264EncoderOnFrame:(H264Encoder *)encoder completedFrameData:(NSData *)frame {
	NSData* sessionIdData = [sessionId dataUsingEncoding:NSASCIIStringEncoding];
	NSMutableData *frameWithSessionId = [NSMutableData dataWithData:sessionIdData];
	[frameWithSessionId appendData:frame];
	[stream appendData:frameWithSessionId];
}

- (void)stopRunning {
	[stream appendData:[sessionId dataUsingEncoding:NSASCIIStringEncoding]];
	[stream close];
#if !(TARGET_IPHONE_SIMULATOR)
	[encoder stopEncoder];
#endif
}

@end