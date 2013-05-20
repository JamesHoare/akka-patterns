#import "ViewController.h"

@interface ViewController () {
	i264Encoder* encoder;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	encoder = [[i264Encoder alloc] initWithDelegate:self];
	[encoder setInPicHeight:[NSNumber numberWithInt:720]];
	[encoder setInPicWidth:[NSNumber numberWithInt:1080]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)startCapture:(id)sender	{
	
	[encoder startEncoder];
	
}

- (void)oni264Encoder:(i264Encoder *)encoder completedFrameData:(NSData *)data {
	NSLog(@"Got data %d", [data length]);
}

@end
