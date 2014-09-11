//
//  LDBDb.m
//  lowladb-objc
//
//  Created by mark on 7/3/14.
//
//

#import <liblowladb/lowladb.h>
#import "LDBCollection.h"
#import "LDBDbPrivate.h"

@implementation LDBDb

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
    }
    return self;
}

- (LDBCollection *)getCollection:(NSString *)name {
    return [[LDBCollection alloc] initWithDb:self andName:name];
}

- (void)ensureOpen {
    if (nullptr == self.pdb) {
        self.pdb = CLowlaDB::open([self.name UTF8String]);
    }
}
@end
