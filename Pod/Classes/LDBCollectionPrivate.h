#import "LDBCollection.h"

@interface LDBCollection ()
@property CLowlaDBCollection::ptr pcoll;

- (void)ensureOpen;
@end

