//
//  LDBObject.m
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#define MONGO_USE_LONG_LONG_INT

#include "liblowladb/lowladb.h"
#import "LDBObjectPrivate.h"
#import "LDBObjectId.h"

@implementation LDBObject
- (id) initWithData:(NSData *)data {
    CLowlaDBBson::ptr bson = CLowlaDBBson::create((char *)[data bytes], false);
    return [self initWithBson:bson ownedBy:data];
}

- (id) initWithBson:(CLowlaDBBson::ptr)bson ownedBy:(NSData *)data {
    if (self = [super init]) {
        self.bson = bson;
        self.data = data;
    }
    return self;
}

- (BOOL)containsField:(NSString *)field {
    return self.bson->containsKey([field UTF8String]);
}

- (double)doubleForField:(NSString *)field {
    double answer;
    if (self.bson->doubleForKey([field UTF8String], &answer)) {
        return answer;
    }
    return 0.0;
}

- (NSString *)stringForField:(NSString *)field {
    return [NSString stringWithUTF8String:self.bson->stringForKey([field UTF8String]).c_str(utf16string::UTF8)];
}

- (LDBObject *)objectForField:(NSString *)field {
    CLowlaDBBson::ptr obj;
    if (self.bson->objectForKey([field UTF8String], &obj)) {
        return [[LDBObject alloc] initWithBson:obj ownedBy:nil];
    }
    else {
        return nil;
    }
}

- (LDBObjectId *)objectIdForField:(NSString *)field {
    char buffer[CLowlaDBBson::OID_SIZE];
    if (self.bson->oidForKey([field UTF8String], buffer)) {
        return [[LDBObjectId alloc] initWithBytes:buffer];
    }
    else {
        return nil;
    }
}

- (BOOL)boolForField:(NSString *)field {
    bool answer;
    if (self.bson->boolForKey([field UTF8String], &answer)) {
        return answer;
    }
    return NO;
}

- (NSDate *)dateForField:(NSString *)field {
    int64_t answer;
    if (self.bson->dateForKey([field UTF8String], &answer)) {
        return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)answer / 1000];
    }
    return nil;
}

- (int)intForField:(NSString *)field {
    int answer;
    if (self.bson->intForKey([field UTF8String], &answer)) {
        return answer;
    }
    return 0;
}

- (int64_t)longForField:(NSString *)field {
    int64_t answer;
    if (self.bson->longForKey([field UTF8String], &answer)) {
        return answer;
    }
    return 0;
}

- (const char *)asBson {
    return self.bson->data();
}

- (BOOL)isEqual:(id)other {
    if (![other isKindOfClass:[LDBObject class]]) {
        return NO;
    }
    if (self.bson->size() != [other bson]->size()) {
        return NO;
    }
    return 0 == memcmp(self.bson->data(), [other bson]->data(), self.bson->size());
}

- (NSUInteger)hash {
    if (nil != self.data) {
        return [self.data hash];
    }
    NSData *data = [NSData dataWithBytesNoCopy:(void *)self.bson->data() length:self.bson->size() freeWhenDone:NO];
    return [data hash];
}

@end
