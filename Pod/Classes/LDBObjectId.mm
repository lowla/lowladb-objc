//
//  LDBObjectId.m
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#include "liblowladb/lowladb.h"
#import "LDBObjectId.h"

@interface LDBObjectId()
@property (readonly) NSData *data;
@end

@implementation LDBObjectId
+ (LDBObjectId *)generate {
    char buffer[CLowlaDBBson::OID_SIZE];
    CLowlaDBBson::oidGenerate(buffer);
    return [[LDBObjectId alloc] initWithBytes:buffer];
}

- (id)initWithBytes:(const char *)bytes {
    if (self = [super init]) {
        _data = [[NSData alloc] initWithBytes:bytes length:CLowlaDBBson::OID_SIZE];
    }
    return self;
}

- (const void *)bytes {
    return [self.data bytes];
}

- (BOOL)isEqual:(id)other {
    return ([other isKindOfClass:[LDBObjectId class]] && [self.data isEqualToData:[other data]]);
}

- (NSUInteger)hash {
    return [self.data hash];
}

- (NSString *)description {
    char buffer[25];
    CLowlaDBBson::oidToString((char *)[self.data bytes], buffer);
    return [NSString stringWithFormat:@"ObjectId(\"%s\")", buffer];
}
@end
