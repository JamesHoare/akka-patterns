#import "QueueStream.h"

@implementation QueueStream {
    NSStreamStatus streamStatus;
	NSData *_data;
}

- (void)open {
	
}

- (void)close {
	
}

- (NSStreamStatus)streamStatus {
    return NSStreamStatusOpen;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not need a run loop to produce its data.
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    // Nothing to do here, because this stream does not need a run loop to produce its data.
}

- (void)appendData:(NSData *)data {
	@synchronized(self) {
		_data = [NSData dataWithData:data];
	}
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
	for (NSUInteger i = 0; i < len; i++) {
		buffer[i] = i;
	}
	return len;
}
// reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
	return NO;
	/*
	@synchronized(self) {
		*len = [_data length];
		*buffer = (uint8_t*)[_data bytes];
	}
	return YES;
	 */
}
// returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available.
// This buffer is only valid until the next stream operation.
// Subclassers may return NO for this if it is not appropriate for the stream type.
// This may return NO if the buffer is not available.

- (BOOL)hasBytesAvailable {
	return YES;
}

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
