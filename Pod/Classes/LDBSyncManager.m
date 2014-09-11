//
//  LDBSyncManager.m
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#import "LDBSyncManager.h"

@implementation LDBSyncManager

+ (LDBSyncManager *)sharedManager {
    static LDBSyncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    if (self = [super init]) {
        _enableBackgroundSync = NO;
    }
    return self;
}
@end
