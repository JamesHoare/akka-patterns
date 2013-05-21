#import <Foundation/Foundation.h>

@interface HSRandomDataInputStream : NSInputStream <NSStreamDelegate> {
@private
    NSData *_data;
	dispatch_semaphore_t _lock;
}
- (id)init;
- (void)setData:(NSData*)data;
@end