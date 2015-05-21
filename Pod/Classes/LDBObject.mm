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
#import "LDBObjectBuilder.h"

static void appendValueToBuilder(NSString *key, id value, LDBObjectBuilder *builder) {
    if ([value isKindOfClass:[NSString class]]) {
        [builder appendString:value forField:key];
    }
    else if ([value isKindOfClass:[NSDate class]]) {
        [builder appendDate:value forField:key];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        id bsonType = [value objectForKey:@"_bsonType"];
        if (bsonType) {
            NSString *type = [bsonType description];
            if ([type isEqualToString:@"ObjectId"]) {
                id hexString = [value objectForKey:@"hexString"];
                if (hexString) {
                    NSString *hex = [hexString description];
                    LDBObjectId *oid = [[LDBObjectId alloc] initWithHexString:hex];
                    [builder appendObjectId:oid forField:key];
                }
            }
        }
        else {
            [builder appendObject:[LDBObject objectWithDictionary:value] forField:key];
        }
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)value;
        const char *type = [num objCType];
        if (0 == strcmp(type, @encode(int))) {
            [builder appendInt:[num intValue] forField:key];
        }
        else if (0 == strcmp(type, @encode(long long))) {
            [builder appendLong:[num longLongValue] forField:key];
        }
        else {
            [builder appendDouble:[num doubleValue] forField:key];
        }
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)value;
        [builder startArrayForField:key];
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *elem = [NSString stringWithFormat:@"%lu", (unsigned long)idx];
            appendValueToBuilder(elem, obj, builder);
        }];
        [builder finishArray];
    }
    else {
        NSDictionary *info = [NSDictionary dictionaryWithObject:key forKey:@"key"];
        NSException *e = [NSException
                          exceptionWithName:@"InvalidTypeException"
                          reason:@"Unsupported object type"
                          userInfo:info];
        @throw e;
        
    }
}

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

+ (id) objectWithDictionary:(NSDictionary *)dict
{
    // We sort the keys to ensure consistent behavior
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    LDBObjectBuilder *builder = [[LDBObjectBuilder alloc] init];
    [sortedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (!([obj isKindOfClass:[NSString class]])) {
            NSDictionary *info = [NSDictionary dictionaryWithObject:[obj description] forKey:@"key"];
            NSException *e = [NSException
                              exceptionWithName:@"InvalidTypeException"
                              reason:@"All keys must be strings"
                              userInfo:info];
            @throw e;
        }
        NSString *key = (NSString *)obj;
        id value = [dict objectForKey:obj];
        appendValueToBuilder(key, value, builder);
    }];
    return [builder finish];
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
    const char *str;
    if (self.bson->stringForKey([field UTF8String], &str)) {
        return [NSString stringWithUTF8String:str];
    }
    else {
        return [NSString stringWithUTF8String:""];
    }
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

- (LDBObject *)arrayForField:(NSString *)field {
    CLowlaDBBson::ptr obj;
    if (self.bson->arrayForKey([field UTF8String], &obj)) {
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

- (NSString *)asJson {
    utf16string json = lowladb_bson_to_json(self.bson->data());
    return [NSString stringWithUTF8String:json.c_str()];
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
