#import "LDBObject.h"
#include "liblowladb/lowladb.h"

@interface LDBObject ()

@property CLowlaDBBson::ptr bson;
@property NSData *data;


- (id)initWithBson:(CLowlaDBBson::ptr)bson ownedBy:(NSData *)data;

@end