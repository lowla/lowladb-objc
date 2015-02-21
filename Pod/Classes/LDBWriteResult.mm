//
//  LDBWriteResult.m
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#include "liblowladb/lowladb.h"
#import "LDBObjectPrivate.h"
#import "LDBWriteResult.h"

@interface LDBWriteResult ()
@property CLowlaDBWriteResult::ptr pwr;
@end

@implementation LDBWriteResult

-(id) initWithImplementation:(CLowlaDBWriteResult::ptr)wr
{
    if (self = [super init]) {
        _pwr = wr;
    }
    return self;
}

- (int)documentCount
{
    return self.pwr->documentCount();
}

-(LDBObject *)document:(int)n
{
    return [[LDBObject alloc] initWithBson:self.pwr->document(n) ownedBy:nil];
}

@end
