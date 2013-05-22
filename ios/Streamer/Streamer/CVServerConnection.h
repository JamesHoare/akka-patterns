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
@end

/**
 * Submits the frames to the server; depending
 */
@protocol CVServerConnectionInput
- (void)submitFrame:(CMSampleBufferRef)frame;
- (void)close;
@end

/**
 * Connects to the server.
 */
@interface CVServerConnection : NSObject
+ (CVServerConnection*)connectionToStream:(NSURL*)url andDelegate:(id<CVServerConnectionDelegate>)delegate;
+ (CVServerConnection*)connectionToStatic:(NSURL*)url andDelegate:(id<CVServerConnectionDelegate>)delegate;
- (id<CVServerConnectionInput>)begin;
@end
