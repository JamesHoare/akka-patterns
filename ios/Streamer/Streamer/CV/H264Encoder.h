#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class H264Encoder;

@protocol H264EncoderDelegate <NSObject>

- (void)h264EncoderOnFrame:(H264Encoder *)encoder completedFrameData:(NSData *)frame;

@end

@interface H264Encoder : NSObject

- (H264Encoder*)initWithDelegate:(id<H264EncoderDelegate>)delegate;
- (bool)startEncoder;
- (bool)stopEncoder;
- (bool)encodePixelBuffer:(CMSampleBufferRef)sampleBuffer;

@property int frameRate;
@property int keyFrameInterval;
@property int height;
@property int width;
@property int bitRate;

@end


