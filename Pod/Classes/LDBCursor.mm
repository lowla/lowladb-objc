//
//  LDBCursor.m
//  lowladb-objc
//
//  Created by mark on 7/11/14.
//
//

#include "lowladb.h"
#import "LDBCollectionPrivate.h"
#import "LDBCursor.h"
#import "LDBObjectPrivate.h"

@interface LDBCursor ()
@property CLowlaDBCursor::ptr pcursor;
@property BOOL readStarted;
@property CLowlaDBBson::ptr nextRecord;
@end

@implementation LDBCursor

-(id) initWithCollection:(LDBCollection *)coll query:(LDBObject *)query keys:(LDBObject *)keys {
    if (self = [super init]) {
        _pcursor = CLowlaDBCursor::create(coll.pcoll);
        _readStarted = NO;
    }
    return self;
}

-(BOOL) hasNext {
    if (!self.readStarted) {
        self.nextRecord = self.pcursor->next();
        self.readStarted = YES;
    }
    return !!self.nextRecord;
}

-(LDBObject *)next {
    if ([self hasNext]) {
        LDBObject *answer = [[LDBObject alloc] initWithBson:self.nextRecord ownedBy:nil];
        self.nextRecord = self.pcursor->next();
        return answer;
    }
    return nil;
}

-(LDBObject *)one {
    CLowlaDBBson::ptr data = self.pcursor->limit(1)->next();
    return [[LDBObject alloc] initWithBson:data ownedBy:nil];
}

@end
