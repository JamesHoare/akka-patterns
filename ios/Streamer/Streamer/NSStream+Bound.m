#import "NSStream+Bound.h"

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
		_lock = dispatch_semaphore_create(0);
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
	dispatch_semaphore_signal(_lock);
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
	dispatch_semaphore_signal(_lock);
}

#pragma mark - NSInputStream subclass overrides

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
	if (streamStatus != NSStreamStatusOpen) return -1;
	
	dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
	if (streamStatus != NSStreamStatusOpen) return -1;

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