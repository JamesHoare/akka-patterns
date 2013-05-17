#import <UIKit/UIKit.h>
#include <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
	
}
- (IBAction)startCapture:(id)sender;

@end
