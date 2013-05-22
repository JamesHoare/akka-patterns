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
- (void)stopRunning;
@end

/**
 * Maintains the connection to the CVServer at some URL; and constructs objects that allow you to submit frames to the
 * server and reports the outcome of the processing that the server performed.
 *
 * Typical usage is (given some ``NSURL* serverUrl`` and ``id<CVServerConnectionDelegate> delegate``:
 * ```
 * @interface X<CVServerConnectionDelegate> 
 * @end
 *
 * @implementation X {
 *   AVCaptureSession* captureSession;
 *   id<CVServerConnectionDelegate> input;
 * }
 *
 * #pragma mark - AV Capture start and stop
 *
 * // when the user decides to start capturing
 * - (void)startCapture {
 *   input = [[CVServerConnection connectionToStream:serverUrl withDelegate:delegate] startRunning];
 *   // start capture session; connecting some AVVideoOutput* to self (implementing AVCaptureVideoDataOutputSampleBufferDelegate) on some queue
 *   captureSession = [[AVCaptureSession alloc] init];
 *   AVVideoOutput *videoOutput = ...
 *   [videoOutput setSampleBufferDelegate:self queue:queue];
 *   ...
 *   [captureSession startRunning];
 * }
 *
 * // when the user decides to stop capture
 * - (void)stopCapture {
 *   [captureSession stopRunning];
 *   [input stopRunning];
 * }
 * 
 * // when frames arrive
 * - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
 *   [input submitFrame:sampleBuffer];
 * }
 *
 *
 * #pragma mark - CVServerConnectionDelegate methods
 *
 * // the CV server accepted the entire operation (potentially consisting of multiple images or streams)
 * - (void)cvServerConnectionOk:(id)response {
 *   NSLog(@":))");
 * }
 *
 * // the CV server accepted the image or stream, but more images or streams must follow
 * - (void)cvServerConnectionAccepted:(id)response {
 *   NSLog(@":)");
 * }
 *
 * // the CV server rejected the image or stream
 * - (void)cvServerConnectionRejected:(id)response {
 *   NSLog(@":(");
 * }
 *
 * // the CV server may have failed or there is no connection to it or something else catastrophic
 * - (void)cvServerConnectionFailed:(NSError *)reason {
 *   NSLog(@":((");
 * }
 *
 *
 * @end
 * ```
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
- (id<CVServerConnectionInput>)startRunning;
@end
