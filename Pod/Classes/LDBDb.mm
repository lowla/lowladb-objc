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

- (NSArray *)collectionNames {
    NSMutableArray *answer = [NSMutableArray array];
    [self ensureOpen];
    
    std::vector<utf16string> names;
    self.pdb->collectionNames(&names);

    for (const utf16string &name : names) {
        [answer addObject:[NSString stringWithUTF8String:name.c_str(utf16string::UTF8)]];
    }
    
    return answer;
}

- (void)ensureOpen {
    if (nullptr == self.pdb) {
        self.pdb = CLowlaDB::open([self.name UTF8String]);
    }
}
@end
