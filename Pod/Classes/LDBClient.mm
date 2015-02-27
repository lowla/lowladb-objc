//
//  LDBClient.m
//  lowladb-objc
//
//  Created by mark on 7/3/14.
//
//

#import "lowladb.h"
#import "LDBDb.h"
#import "LDBClient.h"

@implementation LDBClient

- (NSString *)version {
	return [NSString stringWithFormat:@"0.0.1 (liblowladb %s)", lowladb_get_version().c_str()];
}

- (void) dropDatabase:(NSString *)dbName {
    lowladb_db_delete([dbName UTF8String]);
}

- (LDBDb *)getDatabase:(NSString *)dbName {
    return [[LDBDb alloc] initWithName:dbName];
}

- (NSArray *)getDatabaseNames {
    return nil;
}

- (void)loadJson:(NSString *)json {
    lowladb_load_json([json UTF8String]);
}

@end
