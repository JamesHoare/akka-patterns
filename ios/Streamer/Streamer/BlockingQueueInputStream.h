#import <Foundation/Foundation.h>

@interface BlockingQueueInputStream : NSInputStream {
@private
    NSData *_data;
	dispatch_semaphore_t readLock;
	dispatch_semaphore_t writeLock;
}
- (id)init;
- (void)appendData:(NSData*)data;
@end