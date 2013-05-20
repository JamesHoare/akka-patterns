//
//  QueueStream.h
//  Streamer
//
//  Created by Jan Machacek on 20/05/2013.
//  Copyright (c) 2013 Eigengo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QueueStream : NSInputStream

- (void)appendData:(NSData*)data;

@end
