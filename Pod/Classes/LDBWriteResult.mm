//
//  LDBWriteResult.m
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#include "liblowladb/lowladb.h"
#import "LDBObjectId.h"
#import "LDBWriteResult.h"

@implementation LDBWriteResult

- (id)initWithWriteResult:(CLowlaDBWriteResult::ptr)wr {
    if (self = [super init]) {
        char buffer[CLowlaDBBson::OID_SIZE];
        if (wr->getUpsertedId(buffer)) {
            _upsertedId = [[LDBObjectId alloc] initWithBytes:buffer];
        }
        else {
            _upsertedId = nil;
        }
    }
    return self;
}

@end
