#import "LDBDb.h"

struct CLowlaDB;

@interface LDBDb ()
@property BOOL open;
@property CLowlaDB::ptr pdb;

- (void)ensureOpen;
@end