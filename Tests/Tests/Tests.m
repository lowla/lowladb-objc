//
//  Tests.m
//  lowladb-objcTests
//
//  Created by Mark Dixon on 07/03/2014.
//  Copyright (c) 2014 Mark Dixon. All rights reserved.
//

#import "LDBClient.h"
#import "lowladb-objc/LDBCollection.h"
#import "lowladb-objc/LDBCursor.h"
#import "lowladb-objc/LDBDb.h"
#import "lowladb-objc/LDBObject.h"
#import "lowladb-objc/LDBObjectBuilder.h"
#import "lowladb-objc/LDBObjectId.h"
#import "lowladb-objc/LDBWriteResult.h"

@interface LDB_BasicFunctionalityTests : XCTestCase
@end

@implementation LDB_BasicFunctionalityTests

-(void)testItHasTheCorrectVersion
{
    LDBClient *client = [[LDBClient alloc] init];
    XCTAssertEqualObjects(client.version, @"0.0.1 (liblowladb 0.0.2)");
}

-(void)testItCanCreateDatabaseReferences
{
    LDBClient *client = [[LDBClient alloc] init];
    LDBDb *db = [client getDatabase:@"mydb"];
    XCTAssertEqualObjects(db.name, @"mydb");
}

-(void)testItCanCreateCollectionReferences
{
    LDBClient *client = [[LDBClient alloc] init];
    LDBDb *db = [client getDatabase:@"mydb"];
    LDBCollection *coll = [db getCollection:@"mycoll.dotted"];
    XCTAssertEqualObjects(coll.db, db);
    XCTAssertEqualObjects(coll.name, @"mycoll.dotted");
}

@end

@interface LDB_ObjectBuildingTests : XCTestCase

@end

@implementation LDB_ObjectBuildingTests

-(void)testItCanBuildDoubles
{
    LDBObject *obj = [[[LDBObjectBuilder builder] appendDouble:3.14 forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqual([obj doubleForField:@"myfield"], 3.14);
}

-(void)testItCanBuildStrings
{
    LDBObject *obj = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqualObjects([obj stringForField:@"myfield"], @"mystring");
}

-(void)testItCanBuildObjects
{
    LDBObject *subObj = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    LDBObject *obj = [[[LDBObjectBuilder builder] appendObject:subObj forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqualObjects([obj objectForField:@"myfield"], subObj);
}

-(void)testItCanBuildObjectIds
{
    LDBObjectId *oid = [LDBObjectId generate];
    LDBObject *obj = [[[LDBObjectBuilder builder] appendObjectId:oid forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqualObjects([obj objectIdForField:@"myfield"], oid);
}

-(void)testItCanBuildBools
{
    LDBObject *obj = [[[LDBObjectBuilder builder] appendBool:YES forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqual([obj boolForField:@"myfield"], YES);
}

-(void)testItCanBuildDates
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:60 * 60 * 24];
    LDBObject *obj = [[[LDBObjectBuilder builder] appendDate:date forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    NSTimeInterval i1 = [date timeIntervalSince1970];
    NSTimeInterval i2 = [[obj dateForField:@"myfield"] timeIntervalSince1970];
    XCTAssertEqualWithAccuracy(i1, i2, 1e-3);
    XCTAssertEqual(60 * 60 * 24 * 1000, [obj dateRawForField:@"myfield"]);
}

-(void)testItCanBuildInts
{
    LDBObject *obj = [[[LDBObjectBuilder builder] appendInt:314 forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqual([obj intForField:@"myfield"], 314);
}

-(void)testItCanBuildLongs
{
    LDBObject *obj = [[[LDBObjectBuilder builder] appendLong:314000000000000 forField:@"myfield"] finish];
    XCTAssert([obj containsField:@"myfield"]);
    XCTAssertEqual([obj longForField:@"myfield"], 314000000000000);
}

-(void)testItCanBuildArrays
{
    LDBObject *obj = [[[[[LDBObjectBuilder builder] startArrayForField:@"myarr"] appendInt:5 forField:@"0"] finishArray] finish];
    XCTAssert([obj containsField:@"myarr"]);
    LDBObject *arr = [obj arrayForField:@"myarr"];
    XCTAssertEqual([arr intForField:@"0"], 5);
}

-(void)testItCanReadObjectIdsFromADictionary
{
    NSMutableDictionary *subObj = [NSMutableDictionary dictionary];
    [subObj setObject:@"ObjectId" forKey:@"_bsonType"];
    [subObj setObject:@"0123456789abcdef01234567" forKey:@"hexString"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:subObj forKey:@"_id"];
    
    LDBObject *obj = [LDBObject objectWithDictionary:dict];
    XCTAssertTrue([obj containsField:@"_id"]);
    LDBObjectId *oid = [obj objectIdForField:@"_id"];
    XCTAssertNotNil(oid);
    XCTAssertEqualObjects([oid hexString], @"0123456789abcdef01234567");
}

-(void)testItCanReadArraysFromADictionary
{
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@"mystring"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:arr forKey:@"myarr"];
    
    LDBObject *obj = [LDBObject objectWithDictionary:dict];
    XCTAssertTrue([obj containsField:@"myarr"]);
    LDBObject *sub = [obj arrayForField:@"myarr"];
    XCTAssertEqualObjects([sub stringForField:@"0"], @"mystring");
}

@end

@interface LDB_DbTests : XCTestCase
{
    LDBClient *client;
    LDBDb *db;
}

@end

@implementation LDB_DbTests
    
-(void)setUp
{
    client = [[LDBClient alloc] init];
    [client dropDatabase:@"mydb"];
    db = [client getDatabase:@"mydb"];
}

-(void)tearDown
{
    db = nil;
    [client dropDatabase:@"mydb"];
    client = nil;
}

-(void)testCollectionNames
{
    // No collections to start with
    NSArray *check = [db collectionNames];
    XCTAssertEqual(0, [check count]);
    
    // Create a collection object - this doesn't actually create the collection yet
    LDBCollection *coll = [db getCollection:@"coll"];
    check = [db collectionNames];
    XCTAssertEqual(0, [check count]);
    
    // Insert a document - this will create the collection
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    [coll insert:object];
    check = [db collectionNames];
    XCTAssertEqual(1, [check count]);
    XCTAssertEqualObjects(@"coll", [check objectAtIndex:0]);
    
    // And another collection
    coll = [db getCollection:@"coll2.sub"];
    [coll insert:object];
    check = [db collectionNames];
    XCTAssertEqual(2, [check count]);
    XCTAssertEqualObjects(@"coll", [check objectAtIndex:0]);
    XCTAssertEqualObjects(@"coll2.sub", [check objectAtIndex:1]);
}

@end

@interface LDB_CursorTests : XCTestCase
{
    LDBClient *client;
    LDBDb *db;
    LDBCollection *coll;
}

@end

@implementation LDB_CursorTests

-(void)setUp
{
    client = [[LDBClient alloc] init];
    [client dropDatabase:@"mydb"];
    db = [client getDatabase:@"mydb"];
    coll = [db getCollection:@"mycoll"];
}

-(void)tearDown
{
    coll = nil;
    db = nil;
    [client dropDatabase:@"mydb"];
    client = nil;
}

-(void)testCount
{
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@1}]];
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@2}]];
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@3}]];
    
    XCTAssertEqual(3, [[coll find] count]);
    
    XCTAssertEqual(1, [[coll find:[LDBObject objectWithDictionary:@{@"a":@2}]] count]);
    XCTAssertEqual(2, [[[coll find] limit:2] count]);
    XCTAssertEqual(3, [[[coll find] limit:20] count]);
}

-(void)testSort
{
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@1, @"b":@1}]];
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@2, @"b":@20}]];
    [coll insert:[LDBObject objectWithDictionary:@{@"a":@2, @"b":@30}]];
    
    LDBObject *sort = [[[[LDBObjectBuilder builder] appendInt:1 forField:@"a"] appendInt:-1 forField:@"b"] finish];
    
    LDBCursor *cursor = [[LDBCursor alloc] initWithCollection:coll query:nil keys:nil];
    cursor = [cursor sort:sort];
    LDBObject *doc = [cursor next];
    XCTAssertEqual(1, [doc intForField:@"a"]);
    doc = [cursor next];
    XCTAssertEqual(2, [doc intForField:@"a"]);
    XCTAssertEqual(30, [doc intForField:@"b"]);
    doc = [cursor next];
    XCTAssertEqual(2, [doc intForField:@"a"]);
    XCTAssertEqual(20, [doc intForField:@"b"]);
    doc = [cursor next];
    XCTAssertNil(doc);
}
@end


@interface LDB_CollectionTests : XCTestCase
{
    LDBClient *client;
    LDBDb *db;
    LDBCollection *coll;
}

@end

@implementation LDB_CollectionTests

-(void)setUp
{
    client = [[LDBClient alloc] init];
    [client dropDatabase:@"mydb"];
    db = [client getDatabase:@"mydb"];
    coll = [db getCollection:@"mycoll"];
}

-(void)tearDown
{
    coll = nil;
    db = nil;
    [client dropDatabase:@"mydb"];
    client = nil;
}

-(void)testItCanCreateSingleStringDocuments
{
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    LDBWriteResult *wr = [coll insert:object];
    
    XCTAssertEqual(1, [wr documentCount]);
    XCTAssertNotNil([[wr document:0] objectIdForField:@"_id"]);
}

-(void)testItCreatesANewIdForEachDocument
{
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    LDBWriteResult *wr = [coll insert:object];
    LDBWriteResult *wr2 = [coll insert:object];
    XCTAssertNotEqualObjects([[wr document:0] objectIdForField:@"_id"],
                             [[wr2 document:0] objectIdForField:@"_id"]);
}

-(void)testItCanFindTheFirstDocument
{
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"myfield"] finish];
    LDBWriteResult *wr = [coll insert:object];
    LDBObject *found = [coll findOne];
    NSString *check = [found stringForField:@"myfield"];
    LDBObjectId *checkId = [found objectIdForField:@"_id"];
    XCTAssertEqualObjects(check, @"mystring");
    XCTAssertEqualObjects(checkId, [[wr document:0] objectIdForField:@"_id"]);
}

-(void)testItCanFindTwoDocuments
{
    LDBObject *object1 = [[[LDBObjectBuilder builder] appendString:@"mystring1" forField:@"myfield"] finish];
    LDBWriteResult *wr1 = [coll insert:object1];
    LDBObject *object2 = [[[LDBObjectBuilder builder] appendString:@"mystring2" forField:@"myfield"] finish];
    LDBWriteResult *wr2 = [coll insert:object2];
    LDBCursor *cursor = [coll find];
    XCTAssertTrue([cursor hasNext]);
    LDBObject *check1 = [cursor next];
    XCTAssertTrue([cursor hasNext]);
    LDBObject *check2 = [cursor next];
    XCTAssertFalse([cursor hasNext]);
    XCTAssertEqualObjects([[wr1 document:0] objectIdForField:@"_id"], [check1 objectIdForField:@"_id"]);
    XCTAssertEqualObjects([[wr2 document:0] objectIdForField:@"_id"], [check2 objectIdForField:@"_id"]);
}

-(void)testItCannotInsertDocumentsWithDollarFields
{
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"$myfield"] finish];
    
    XCTAssertThrowsSpecificNamed([coll insert:object], NSException, NSInvalidArgumentException);
}

-(void)testItCannotInsertDocumentsWithDollarFieldsViaArray
{
    LDBObject *object = [[[LDBObjectBuilder builder] appendString:@"mystring" forField:@"$myfield"] finish];

    NSArray *arr = [NSArray arrayWithObjects:object, object, nil];
    XCTAssertThrowsSpecificNamed([coll insertArray:arr], NSException, NSInvalidArgumentException);
    
}

-(void)testItCanRemoveADocument
{
    LDBObject *object1 = [[[LDBObjectBuilder builder] appendInt:1 forField:@"a"] finish];
    [coll insert:object1];
    LDBObject *object2 = [[[LDBObjectBuilder builder] appendInt:2 forField:@"a"] finish];
    [coll insert:object2];
    LDBObject *object3 = [[[LDBObjectBuilder builder] appendInt:3 forField:@"a"] finish];
    [coll insert:object3];
    
    LDBObject *query = [[[LDBObjectBuilder builder] appendInt:2 forField:@"a"] finish];
    LDBWriteResult *wr = [coll remove:query];
    XCTAssertEqual(1, [wr documentCount]);
    
    LDBCursor *cursor = [coll find];
    LDBObject *doc = [cursor next];
    XCTAssertEqual(1, [doc intForField:@"a"]);
    doc = [cursor next];
    XCTAssertEqual(3, [doc intForField:@"a"]);
    doc = [cursor next];
    XCTAssertNil(doc);
}

-(void)testItCanRemoveAllDocuments
{
    LDBObject *object1 = [[[LDBObjectBuilder builder] appendInt:1 forField:@"a"] finish];
    [coll insert:object1];
    LDBObject *object2 = [[[LDBObjectBuilder builder] appendInt:2 forField:@"a"] finish];
    [coll insert:object2];
    LDBObject *object3 = [[[LDBObjectBuilder builder] appendInt:3 forField:@"a"] finish];
    [coll insert:object3];
    
    LDBWriteResult *wr = [coll remove:nil];
    XCTAssertEqual(3, [wr documentCount]);
    
    LDBCursor *cursor = [coll find];
    LDBObject *doc = [cursor next];
    XCTAssertNil(doc);
}

- (void) testItCanUpdateADocument
{
    LDBObject *object1 = [[[LDBObjectBuilder builder] appendInt:1 forField:@"a"] finish];
    [coll insert:object1];
    LDBObject *object2 = [[[LDBObjectBuilder builder] appendInt:2 forField:@"a"] finish];
    [coll insert:object2];
    
    LDBObject *query = [[[LDBObjectBuilder builder] appendInt:2 forField:@"a"] finish];
    LDBObject *update = [[[LDBObjectBuilder builder] appendInt:3 forField:@"a"] finish];

    LDBWriteResult *wr = [coll update:query object:update];
    XCTAssertEqual(1, [wr documentCount]);

    LDBCursor *cursor = [coll find];
    LDBObject *obj = [cursor next];
    XCTAssertEqual(1, [obj intForField:@"a"]);
    obj = [cursor next];
    XCTAssertEqual(3, [obj intForField:@"a"]);
    obj = [cursor next];
    XCTAssertNil(obj);
}

@end

// Trivial mock http 'server' that records any requests made and sends back prepared json responses.
@interface LDBMockServer : NSObject
{
}
@property int requestCount;
@property NSMutableArray *requests;
@property NSMutableArray *responses;

- (id)init;
- (void)handleRequest:(NSURLProtocol *)protocol;
@end

@implementation LDBMockServer

- (id)init {
    if ((self = [super init])) {
        _requestCount = 0;
        _requests = [NSMutableArray array];
        _responses = [NSMutableArray array];
    }
    return self;
}

- (void)handleRequest:(NSURLProtocol *)protocol {
    [self.requests addObject:[protocol request]];
    if (self.requestCount < [self.responses count]) {
        NSData *responseData = (NSData *)[self.responses objectAtIndex:self.requestCount];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[protocol.request URL] MIMEType:@"application/json" expectedContentLength: [responseData length] textEncodingName:@"UTF8"];
        [protocol.client URLProtocol:protocol didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [protocol.client URLProtocol:protocol didLoadData:responseData];
        [protocol.client URLProtocolDidFinishLoading:protocol];
    }
    else {
        NSError *error = [NSError errorWithDomain:@"LDBServer ran out of responses" code:0 userInfo:nil];
        [protocol.client URLProtocol:protocol didFailWithError:error];
    }
    ++self.requestCount;
}

@end

static LDBMockServer *server;

@interface LDBSyncTestProtocol : NSURLProtocol
{
}
@end

@implementation LDBSyncTestProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [[[request URL] scheme] isEqualToString:@"test"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    [server handleRequest:self];
}

- (void)stopLoading {
}

@end

@interface LDB_SyncTests : LDB_CollectionTests
{
}
@end

@implementation LDB_SyncTests

- (void) setUp {
    [super setUp];
    [NSURLProtocol registerClass:[LDBSyncTestProtocol class]];
    server = [[LDBMockServer alloc] init];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:LDBClientSequenceProperty];
}

- (void) tearDown {
    server = nil;
    [NSURLProtocol unregisterClass:[LDBSyncTestProtocol class]];
    [super tearDown];
}

- (void) pushResponse:(NSString *)json {
    [server.responses addObject:[json dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *) requestUrl:(int) index {
    return [[((NSURLRequest *)[server.requests objectAtIndex:index]) URL] description];
}

- (long) lastSequence {
    return [[NSUserDefaults standardUserDefaults] integerForKey:LDBClientSequenceProperty];
}

- (void) testNoOpSync
{
    XCTestExpectation *te = [self expectationWithDescription:@"Sync complete"];

    [self pushResponse:@"{ \"atoms\" : [], \"sequence\" : 2}"];
    
    [LDBClient sync:@"test://" notify:^(LDBSyncStatus status, NSString *message) {
        if (LDBSyncStatus_ERROR == status || LDBSyncStatus_OK == status) {
            XCTAssertEqual(LDBSyncStatus_OK, status);
            [te fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:10000 handler:^(NSError *error) {
        // No pushes, no pulls, just the changes request
        XCTAssertEqual(1, server.requestCount);
        XCTAssertEqualObjects(@"test:///_lowla/changes?seq=0", [self requestUrl:0]);
        XCTAssertEqual(2, [self lastSequence]);
    }];
}

- (void) testOnePullSync
{
    XCTestExpectation *te = [self expectationWithDescription:@"Sync complete"];
    
    [self pushResponse:@"{ \"atoms\" : [{ \"id\" : \"mydb.mycoll$1\", \"sequence\" : 1, \"version\" : 1, \"deleted\" : false, \"clientNs\" : \"mydb.mycoll\" }], \"sequence\" : 2}"];
    [self pushResponse:@"[{ \"id\" : \"mydb.mycoll$1\", \"clientNs\" : \"mydb.mycoll\" }, { \"_id\" : \"1\", \"myfield\" : \"myvalue\" }]"];
    [self pushResponse:@"{ \"atoms\" : [], \"sequence\" : 2}"];
    
    [LDBClient sync:@"test://" notify:^(LDBSyncStatus status, NSString *message) {
        if (LDBSyncStatus_ERROR == status || LDBSyncStatus_OK == status) {
            XCTAssertEqual(LDBSyncStatus_OK, status);
            XCTAssertEqual(2, [self lastSequence]);
            // And sync again to make sure we don't try to push up the new record
            [LDBClient sync:@"test://" notify:^(LDBSyncStatus status, NSString *message) {
                if (LDBSyncStatus_ERROR == status || LDBSyncStatus_OK == status) {
                    XCTAssertEqual(LDBSyncStatus_OK, status);
                    [te fulfill];
                }
            }];
        }
    }];
    
    [self waitForExpectationsWithTimeout:10000 handler:^(NSError *error) {
        // The first sync has two requests: changes and pull
        // The second sync has one: changes
        XCTAssertEqual(3, server.requestCount);
        XCTAssertEqualObjects(@"test:///_lowla/changes?seq=0", [self requestUrl:0]);
        XCTAssertEqualObjects(@"test:///_lowla/pull", [self requestUrl:1]);
        XCTAssertEqualObjects(@"test:///_lowla/changes?seq=2", [self requestUrl:2]);
        XCTAssertEqual(2, [self lastSequence]);
    }];
}

- (void) testOneDeletionChangeDoesntPull
{
    XCTestExpectation *te = [self expectationWithDescription:@"Sync complete"];
    
    [self pushResponse:@"{ \"atoms\" : [{ \"id\" : \"mydb.mycoll$1\", \"sequence\" : 1, \"version\" : 1, \"deleted\" : true, \"clientNs\" : \"mydb.mycoll\" }], \"sequence\" : 2}"];
    
    [LDBClient sync:@"test://" notify:^(LDBSyncStatus status, NSString *message) {
        if (LDBSyncStatus_ERROR == status || LDBSyncStatus_OK == status) {
            XCTAssertEqual(LDBSyncStatus_OK, status);
            XCTAssertEqual(2, [self lastSequence]);
            [te fulfill];
        }
    }];

    [self waitForExpectationsWithTimeout:10000 handler:^(NSError *error) {
        // As an optimization, we shouldn't try to pull 0 records from the adapter. So there should only be the changes request
        XCTAssertEqual(1, server.requestCount);
        XCTAssertEqualObjects(@"test:///_lowla/changes?seq=0", [self requestUrl:0]);
    }];
}
@end
