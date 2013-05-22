#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CVServer/CVServerConnection.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, CVServerConnectionDelegate> {
	
}
- (IBAction)startCapture:(id)sender;
- (IBAction)stopCapture:(id)sender;
@end
