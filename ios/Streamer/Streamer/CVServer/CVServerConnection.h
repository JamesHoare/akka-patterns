#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 * Implement this delegate to receive notifications from the ``CVServerConnection``
 */
@protocol CVServerConnectionDelegate
  /**
   * This is the 200 response from the server. The image or stream was accepted.
   */
- (void)cvServerConnectionOk:(id)response;

  /**
   * This is the 202 response from the server. The image or stream was accepted, but more
   * images or streams are expected before ``-cvServerConnectionOk`` may be called.
   */
- (void)cvServerConnectionAccepted:(id)response;

  /**
   * This is the 400 response from the server. The image or stream is not acceptable and
   * sending the same image or stream will not succeed.
   */
- (void)cvServerConnectionRejected:(id)response;

  /**
   * The server has failed: either HTTP 500 or no connection or such like.
   */
- (void)cvServerConnectionFailed:(NSError*)reason;
@end

/**
 * Submits the frames to the server
 */
@protocol CVServerConnectionInput
  /**
   * Submit a frame to the server endpoint
   */
- (void)submitFrame:(CMSampleBufferRef)frame;
  /**
   * Complete the stream of frames
   */
- (void)close;
@end

/**
 * Connects to the server.
 */
@interface CVServerConnection : NSObject
  /**
   * Constructs ``CVServerConnection`` that sends H.264 stream to the server at ``url``, informing the ``delegate`` of the
   * ultimate results.
   */
+ (CVServerConnection*)connectionToStream:(NSURL*)url withDelegate:(id<CVServerConnectionDelegate>)delegate;
  /**
   * Constructs ``CVServerConnection`` that sends JPEG images to the server at ``url``, informing the ``delegate`` of the
   * ultimate results.
   */
+ (CVServerConnection*)connectionToStatic:(NSURL*)url withDelegate:(id<CVServerConnectionDelegate>)delegate;
  /**
   * Obtains the input that allows you to submit the frames. Depending on the way in which you constructed this object,
   * the ``delegate`` will receive response after the frame (static) or after you call the returned object's ``-close`` 
   * method (stream).
   */
- (id<CVServerConnectionInput>)begin;
@end
