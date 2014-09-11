//
//  Tests.m
//  lowladb-objcTests
//
//  Created by Mark Dixon on 07/03/2014.
//  Copyright (c) 2014 Mark Dixon. All rights reserved.
//

#import "lowladb-objc/LDBClient.h"
#import "lowladb-objc/LDBCollection.h"
#import "lowladb-objc/LDBCursor.h"
#import "lowladb-objc/LDBDb.h"
#import "lowladb-objc/LDBObject.h"
#import "lowladb-objc/LDBObjectBuilder.h"
#import "lowladb-objc/LDBObjectId.h"
#import "lowladb-objc/LDBWriteResult.h"

SpecBegin(lowladb)

describe(@"basic functionality", ^{
    it(@"has the correct version", ^{
        LDBClient *client = [[LDBClient alloc] init];
        expect(client.version).to.equal(@"0.1.0");
    });
    
    it (@"can create database references", ^{
        LDBClient *client = [[LDBClient alloc] init];
        LDBDb *db = [client getDatabase:@"mydb"];
        expect(db.name).to.equal(@"mydb");
    });
    
    it (@"can create collection references", ^{
        LDBClient *client = [[LDBClient alloc] init];
        LDBDb *db = [client getDatabase:@"mydb"];
        LDBCollection *coll = [db getCollection:@"mycoll.dotted"];
        expect(coll.db).to.equal(db);
        expect(coll.name).to.equal(@"mycoll.dotted");
    });
});

describe(@"object building", ^{
    it(@"can build doubles", ^{
        LDBObject *obj = [[[LDBObjectBuilder builder] appendDouble:3.14 forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj doubleForField:@"myfield"]).to.equal(3.14);
    });
    
    it(@"can build strings", ^{
        LDBObject *obj = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj stringForField:@"myfield"]).to.equal(@"mystring");
    });
    
    it(@"can build objects", ^{
        LDBObject *subObj = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
        LDBObject *obj = [[[LDBObjectBuilder builder] appendObject:subObj forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj objectForField:@"myfield"]).to.equal(subObj);
    });
    
    it(@"can build objectIds", ^{
        LDBObjectId *oid = [LDBObjectId generate];
        LDBObject *obj = [[[LDBObjectBuilder builder] appendObjectId:oid forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj objectIdForField:@"myfield"]).to.equal(oid);
    });
    
    it(@"can build bools", ^{
        LDBObject *obj = [[[LDBObjectBuilder builder] appendBool:YES forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj boolForField:@"myfield"]).to.equal(YES);
    });
    
    it (@"can build dates", ^{
        NSDate *date = [NSDate date];
        LDBObject *obj = [[[LDBObjectBuilder builder] appendDate:date forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        NSTimeInterval i1 = [date timeIntervalSince1970];
        NSTimeInterval i2 = [[obj dateForField:@"myfield"] timeIntervalSince1970];
        expect(i1).beCloseTo(i2);
    });
    
    it(@"can build ints", ^{
        LDBObject *obj = [[[LDBObjectBuilder builder] appendInt:314 forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj intForField:@"myfield"]).to.equal(314);
    });

    it(@"can build longs", ^{
        LDBObject *obj = [[[LDBObjectBuilder builder] appendLong:314000000000000 forField:@"myfield"] finish];
        expect([obj containsField:@"myfield"]).to.beTruthy();
        expect([obj longForField:@"myfield"]).to.equal(314000000000000);
    });

});

describe(@"basic insert and retrieval", ^{
    __block LDBClient *client;
    __block LDBDb *db;
    __block LDBCollection *coll;
    
    beforeEach(^{
        client = [[LDBClient alloc] init];
        [client dropDatabase:@"mydb"];
        db = [client getDatabase:@"mydb"];
        coll = [db getCollection:@"mycoll"];
    });
    
    afterEach(^{
        coll = nil;
        db = nil;
        [client dropDatabase:@"mydb"];
        client = nil;
    });
    
    it (@"can create single string documents", ^{
        LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
        LDBWriteResult *wr = [coll insert:object];
        expect(wr.upsertedId).notTo.equal(nil);
    });
    
    it (@"creates a new id for each document", ^{
        LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
        LDBWriteResult *wr = [coll insert:object];
        LDBWriteResult *wr2 = [coll insert:object];
        NSLog(@"%@->%@", wr.upsertedId, wr2.upsertedId);
        expect(wr.upsertedId).notTo.equal(wr2.upsertedId);
    });
    
    it (@"can find the first document", ^{
        LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
        LDBWriteResult *wr = [coll insert:object];
        LDBObject *found = [coll findOne];
        NSString *check = [found stringForField:@"myfield"];
        LDBObjectId *checkId = [found objectIdForField:@"_id"];
        expect(check).to.equal(@"mystring");
        expect(checkId).to.equal(wr.upsertedId);
    });
    
    it (@"can find two documents", ^{
        // The tests need an autoreleasepool to free the ExpExpect objects since they own their blocks that, in turn,
        // own references to the cursor. Not freeing the cursor prevents us freeing the database in afterEach.
        @autoreleasepool {
        LDBObject *object1 = [[[LDBObjectBuilder builder] appendString:@"mystring1" forField:@"myfield"] finish];
        LDBWriteResult *wr1 = [coll insert:object1];
        LDBObject *object2 = [[[LDBObjectBuilder builder] appendString:@"mystring2" forField:@"myfield"] finish];
        LDBWriteResult *wr2 = [coll insert:object2];
        LDBCursor *cursor = [coll find];
        expect([cursor hasNext]).to.beTruthy();
        LDBObject *check1 = [cursor next];
        expect([cursor hasNext]).to.beTruthy();
        LDBObject *check2 = [cursor next];
        expect([cursor hasNext]).to.beFalsy;
        expect([wr1 upsertedId]).to.equal([check1 objectIdForField:@"_id"]);
        expect([wr2 upsertedId]).to.equal([check2 objectIdForField:@"_id"]);
        }
    });
});

SpecEnd
