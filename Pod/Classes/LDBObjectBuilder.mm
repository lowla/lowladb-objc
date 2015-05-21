//
//  LDBObjectBuilder.m
//  lowladb-objc
//
//  Created by mark on 7/15/14.
//
//

#import "LDBObjectBuilder.h"
#import "LDBObjectPrivate.h"
#import "LDBObjectId.h"

#include "liblowladb/lowladb.h"

@interface LDBObjectBuilder()

@property CLowlaDBBson::ptr bson;

@end
@implementation LDBObjectBuilder

+ (LDBObjectBuilder *)builder {
    return [[LDBObjectBuilder alloc] init];
}

- (id) init {
    if (self = [super init]) {
        _bson = CLowlaDBBson::create();
    }
    return self;
}

- (LDBObjectBuilder *)appendDouble:(double)value forField:(NSString *)field {
    self.bson->appendDouble([field UTF8String], value);
    return self;
}

- (LDBObjectBuilder *)appendString:(NSString *)value forField:(NSString *)field {
    self.bson->appendString([field UTF8String], [value UTF8String]);
    return self;
}

- (LDBObjectBuilder *)appendObject:(LDBObject *)value forField:(NSString *)field {
    self.bson->appendObject([field UTF8String], (const char *)[value asBson]);
    return self;
}

- (LDBObjectBuilder *)appendObjectId:(LDBObjectId *)value forField:(NSString *)field {
    self.bson->appendOid([field UTF8String], [value bytes]);
    return self;
}

- (LDBObjectBuilder *)appendBool:(BOOL)value forField:(NSString *)field {
    self.bson->appendBool([field UTF8String], value);
    return self;
}

- (LDBObjectBuilder *)appendDate:(NSDate *)value forField:(NSString *)field {
    self.bson->appendDate([field UTF8String], (int64_t)([value timeIntervalSince1970] * 1000));
    return self;
}

- (LDBObjectBuilder *)appendInt:(int)value forField:(NSString *)field {
    self.bson->appendInt([field UTF8String], value);
    return self;
}

- (LDBObjectBuilder *)appendLong:(int64_t)value forField:(NSString *)field {
    self.bson->appendLong([field UTF8String], value);
    return self;
}

- (LDBObjectBuilder *)startArrayForField:(NSString *)field {
    self.bson->startArray([field UTF8String]);
    return self;
}

- (LDBObjectBuilder *)finishArray {
    self.bson->finishArray();
    return self;
}

- (LDBObject *)finish {
    self.bson->finish();
    return [[LDBObject alloc] initWithBson:self.bson ownedBy:nil];
}

@end
