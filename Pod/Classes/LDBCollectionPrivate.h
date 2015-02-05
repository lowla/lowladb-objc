#import "LDBCollection.h"

@interface LDBCollection ()
{
    CLowlaDBCollection::ptr _pcoll;
}

@property CLowlaDBCollection::ptr pcoll;

- (void) ensureOpen;
- (CLowlaDBCollection::ptr) pcoll;
- (void) setPcoll:(CLowlaDBCollection::ptr)pcoll;

@end

