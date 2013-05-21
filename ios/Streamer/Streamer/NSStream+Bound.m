#import "NSStream+Bound.h"

@implementation NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(out NSInputStream * __strong*)inputStreamPtr outputStream:(out NSOutputStream * __strong*)outputStreamPtr bufferSize:(NSUInteger)bufferSize {
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
	
    assert((inputStreamPtr != NULL) || (outputStreamPtr != NULL));
	
    readStream = NULL;
    writeStream = NULL;
	
    CFStreamCreateBoundPair(kCFAllocatorDefault,
							((inputStreamPtr  != nil) ? &readStream : NULL),
							((outputStreamPtr != nil) ? &writeStream : NULL),
							(CFIndex) bufferSize);
	
    if (inputStreamPtr != NULL) {
        *inputStreamPtr = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end
