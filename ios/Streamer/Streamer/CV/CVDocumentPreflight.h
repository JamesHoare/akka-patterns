#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef struct {
	bool leftEdge;
	bool rightEdge;
	bool bottomEdge;
	bool topEdge;
	
	bool face;
	
	bool focus;
} CVDocumentPreflightResult;

@interface CVDocumentPreflight : NSObject
- (CVDocumentPreflightResult)preflight:(CGImageRef)frame;
@end
