#import <Foundation/Foundation.h>

@interface HSRandomDataInputStream : NSInputStream <NSStreamDelegate> {
@private
    NSData *_data;
	dispatch_semaphore_t readLock;
	dispatch_semaphore_t writeLock;
}
- (id)init;
- (void)setData:(NSData*)data;
@end