#import <Foundation/Foundation.h>

@interface NSStream (BoundPairAdditions)
+ (void)createBoundInputStream:(out NSInputStream * __strong*)inputStreamPtr outputStream:(out NSOutputStream * __strong*)outputStreamPtr bufferSize:(NSUInteger)bufferSize;
@end

@interface HSRandomDataInputStream : NSInputStream <NSStreamDelegate> {
@private
    
}

@end