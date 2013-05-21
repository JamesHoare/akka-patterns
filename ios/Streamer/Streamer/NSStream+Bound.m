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


@implementation HSRandomDataInputStream
{
    NSStreamStatus streamStatus;
    
    id <NSStreamDelegate> delegate;
    
	CFReadStreamClientCallBack copiedCallback;
	CFStreamClientContext copiedContext;
	CFOptionFlags requestedEvents;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        streamStatus = NSStreamStatusNotOpen;
		_lock = [[NSLock alloc] init];
		_data = nil;
    }
    
    return self;
}

#pragma mark - NSStream subclass overrides

- (void)open {
    streamStatus = NSStreamStatusOpen;
}

- (void)close {
    streamStatus = NSStreamStatusClosed;
}

- (id<NSStreamDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)aDelegate {
    delegate = aDelegate;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not need a run loop to produce its data.
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not need a run loop to produce its data.
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

- (NSStreamStatus)streamStatus {
    return streamStatus;
}

- (NSError *)streamError {
    return nil;
}

- (void)setData:(NSData *)data {
	_data = data;
	[_lock unlock];
}

#pragma mark - NSInputStream subclass overrides

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
	[_lock lock];
	NSUInteger readLen = MIN([_data length], len);
	uint8_t* dataBuffer = (uint8_t*)[_data bytes];
	for (NSUInteger i = 0; i < readLen; i++) {
		buffer[i] = dataBuffer[i];
	}
	
	return readLen;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
	// Not appropriate for this kind of stream; return NO.
	return NO;
}

- (BOOL)hasBytesAvailable {
	// There are always bytes available.
	return YES;
}

#pragma mark - Undocumented CFReadStream bridged methods

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
	// Nothing to do here, because this stream does not need a run loop to produce its data.
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFReadStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {
	return YES;
}

- (void)_unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
	// Nothing to do here, because this stream does not need a run loop to produce its data.
}


@end