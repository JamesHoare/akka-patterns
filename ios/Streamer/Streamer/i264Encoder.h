
// Add AVFoundation,Security,CoreVideo,CoreMedia to the project, otherwise you will get linking errors.

#define H264Baseline30 1
#define H264Baseline31 2

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>


@interface i264Encoder : NSObject {	
	
	
	NSNumber *frameRate;
	
	NSNumber *outPicHeight;
	NSNumber *outPicWidth;
	NSNumber *bitRate;
	NSNumber *keyFrameInterval;
	NSNumber *profileLevel;	
	NSNumber *avgDataRate;
	NSNumber *dataLimitRate;
	
	NSNumber *inPicHeight;
	NSNumber *inPicWidth;	
	NSNumber *inPixelBufferFormat;	
	
	id theDelegate;
	
	
}

//User methods

-(BOOL)startEncoder; /* you must start the encoder after you intialized the input H264 parameters */
-(BOOL)startEncoderWithFile:(NSString *)validFileNameWithPath; /* start the encoder with file name to save the stream as a valid movie file */
-(BOOL)stopEncoder;  /* To stop the encoding, use this method. */
-(BOOL)encodePixelBuffer:(CVPixelBufferRef)inPixelBuffer; /* call this method to encode the picture 
														   (you have to call the startEncoder before calling this method) */
-(NSData *)wantSPSAndPPSData;  /* use this method to access SPS PPS headers, don't release return NSData object, it is an autorelease object */
-(NSData *)wantSPSData; /* Return SPS data, don't release return NSData object, it is an autorelease object */
-(NSData *)wantPPSData; /* Return PPS data, don't release return NSData object, it is an autorelease object */

//Internal Methods
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (id)initWithDelegate:(id)delegate;

//These are H264 parameters need to be set. (before calling startEncoder) method)
@property (retain,nonatomic)  NSNumber *frameRate;	/* optional (default 30fp)s*/
@property (retain,nonatomic)  NSNumber *keyFrameInterval; /*optional*/
@property (retain,nonatomic)  NSNumber *profileLevel;	  /*optional*/
@property (retain,nonatomic)  NSNumber *inPicHeight;      /* must be non null*/
@property (retain,nonatomic)  NSNumber *inPicWidth;	    /* must be non null*/
@property (retain,nonatomic)  NSNumber *bitRate;	/*optional*/
@property (retain,nonatomic)  NSNumber *avgDataRate;	    /*optional*/
@property (retain,nonatomic)  NSNumber *dataLimitRate;	    /*optional*/


@property (retain,nonatomic)  NSNumber *inPixelBufferFormat;/*Input pixel buffer format
															 for better performance use  
															 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or
															 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange */															  

@property (retain,nonatomic)  NSNumber *outPicHeight; /* if outPicHeight is nil, it automatically sets to the inPicHeight */
@property (retain,nonatomic)  NSNumber *outPicWidth;  /* If outPicWidth is nil, it defaults to outPicWidth */



@end

@interface NSObject (i264EncoderDelegate)

- (void)oni264Encoder:(i264Encoder *)encoder completedFrameData:(NSData *)data;
/* This delegate method invokes when an picture is encoded and data will be passed to it.
 You need to copy the data but dont release or retain. */

@end
