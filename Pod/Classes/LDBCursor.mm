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

-(id) initWithImplementation:(CLowlaDBCursor::ptr)pcursor
{
    if (self = [super init]) {
        _pcursor = pcursor;
        _readStarted = NO;
    }
    return self;
}

-(id) initWithCollection:(LDBCollection *)coll query:(LDBObject *)query keys:(LDBObject *)keys
{
    const char *queryArg = nullptr;
    if (query) {
        queryArg = [query asBson];
    }
    CLowlaDBCursor::ptr pcursor = CLowlaDBCursor::create(coll.pcoll, queryArg);
    return [self initWithImplementation:pcursor];
}

- (LDBCursor *)limit:(int)limit
{
    CLowlaDBCursor::ptr pcursor = _pcursor->limit(limit);
    return [[LDBCursor alloc] initWithImplementation:pcursor];
}

- (LDBCursor *)sort:(LDBObject *)sort
{
    CLowlaDBCursor::ptr pcursor = _pcursor->sort([sort asBson]);
    return [[LDBCursor alloc] initWithImplementation:pcursor];
}

- (LDBCursor *)showPending
{
    CLowlaDBCursor::ptr pcursor = _pcursor->showPending();
    return [[LDBCursor alloc] initWithImplementation:pcursor];
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

- (int64_t)count {
    return self.pcursor->count();
}

@end
