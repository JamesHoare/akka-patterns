#import <UIKit/UIKit.h>
#include <AVFoundation/AVFoundation.h>
#include "i264Encoder.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, NSURLConnectionDelegate> {
	
}
- (IBAction)startCapture:(id)sender;
- (IBAction)stopCapture:(id)sender;
@end
