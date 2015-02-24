//
//  LDBCollection.m
//  lowladb-objc
//  Created by mark on 7/8/14.
//
//

#import "liblowladb/TeamstudioException.h"
#import "liblowladb/lowladb.h"
#import "LDBCollectionPrivate.h"
#import "LDBCursor.h"
#import "LDBDbPrivate.h"
#import "LDBObject.h"
#import "LDBWriteResultPrivate.h"

@implementation LDBCollection

- (id)initWithDb:(LDBDb *)db andName:(NSString *)name {
    if (self = [super init]) {
        _db = db;
        _name = name;
    }
    return self;
}

- (void)ensureOpen {
    [self.db ensureOpen];
    if (nullptr == _pcoll) {
        _pcoll = self.db.pdb->createCollection([self.name UTF8String]);
    }
}

- (CLowlaDBCollection::ptr) pcoll {
    [self ensureOpen];
    return _pcoll;
}

- (void)setPcoll:(CLowlaDBCollection::ptr)pcoll {
    _pcoll = pcoll;
}

- (LDBCursor *)find {
    return [[LDBCursor alloc] initWithCollection:self query:nil keys:nil];
}

- (LDBObject *)findOne {
    return [[[LDBCursor alloc] initWithCollection:self query:nil keys:nil] one];
}

- (LDBCursor *)find:(LDBObject *)query {
    return [[LDBCursor alloc] initWithCollection:self query:query keys:nil];
    
}

- (LDBObject *)findOne:(LDBObject *)query {
    return [[[LDBCursor alloc] initWithCollection:self query:query keys:nil] one];
}

- (LDBWriteResult *) insert:(LDBObject *)object {
    [self ensureOpen];
    const char *bson = (const char *)[object asBson];
    try {
        CLowlaDBWriteResult::ptr wr = self.pcoll->insert(bson);
        return [[LDBWriteResult alloc] initWithImplementation:wr];
    }
    catch (TeamstudioException &e) {
        NSException *ex = [NSException
                          exceptionWithName:NSInvalidArgumentException
                          reason:@(e.what())
                          userInfo:nil];
        @throw ex;
    }
}

- (LDBWriteResult *)insertArray:(NSArray *)arr {
    [self ensureOpen];
    __block std::vector<const char *> bsonArr;
    [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[LDBObject class]]) {
            NSException *e = [NSException
                              exceptionWithName:@"InvalidTypeException"
                              reason:@"All elements must be LDBObjects"
                              userInfo:nil];
            @throw e;
        }
        bsonArr.push_back((const char *)[obj asBson]);
    }];
    CLowlaDBWriteResult::ptr wr = self.pcoll->insert(bsonArr);
    return [[LDBWriteResult alloc] initWithImplementation:wr];
}

- (LDBWriteResult *)remove:(LDBObject *)query {
    [self ensureOpen];
    const char *bson = nullptr;
    if (query) {
        bson = [query asBson];
    }
    CLowlaDBWriteResult::ptr wr = self.pcoll->remove(bson);
    return [[LDBWriteResult alloc] initWithImplementation:wr];
}

- (LDBWriteResult *)save:(LDBObject *)object {
    [self ensureOpen];
    const char *bson = [object asBson];
    CLowlaDBWriteResult::ptr wr = self.pcoll->save(bson);
    return [[LDBWriteResult alloc] initWithImplementation:wr];
}

- (LDBWriteResult *)update:(LDBObject *)query object:(LDBObject *)object {
    return [self update:query object:object upsert:NO multi:NO];
}

- (LDBWriteResult *)update:(LDBObject *)query object:(LDBObject *)object upsert:(BOOL)upsert multi:(BOOL)multi {
    [self ensureOpen];
    const char *queryBson = [query asBson];
    const char *objectBson = [object asBson];
    CLowlaDBWriteResult::ptr wr = self.pcoll->update(queryBson, objectBson, upsert, multi);
    return [[LDBWriteResult alloc] initWithImplementation:wr];
}

- (LDBWriteResult *)updateMulti:(LDBObject *)query object:(LDBObject *)object {
    return [self update:query object:object upsert:NO multi:YES];
}

@end
