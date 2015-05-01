//
//  LDBClient.m
//  lowladb-objc
//
//  Created by mark on 7/3/14.
//
//

#import "AFNetworking.h"
#import "lowladb.h"
#import "LDBDb.h"
#import "LDBClient.h"

NSString *LDBClientDidChangeCollectionNotification = @"LDBClientDidChangeCollectionNotification";

NSString *LDBClientSequenceProperty = @"sequence";

void listener(void *user, const char *ns) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSDictionary *userInfo = @{@"ns": [NSString stringWithUTF8String:ns]};
    [nc postNotificationName:LDBClientDidChangeCollectionNotification object:nil userInfo:userInfo];
}

static void doPost(NSString *url, CLowlaDBBson::ptr bson, void (^success)(id responseObject), void (^failure)(NSError *error)) {
    utf16string json = lowladb_bson_to_json(bson->data());
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    
    [request setHTTPMethod:@"POST"];
    [request setValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    const char *utf8 = json.c_str();
    NSData *data = [NSData dataWithBytes:(void *)utf8 length:strlen(utf8)];
    [request setHTTPBody: data];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
    [op start];
    
}

static void pullChunk(NSString *server, CLowlaDBPullData::ptr pd, SyncNotifier notify) {
    // Create the pull request before checking for isComplete because the act of
    // building the request may complete the pull (e.g. if we already have all the documents)
    CLowlaDBBson::ptr pullRequestBson = lowladb_create_pull_request(pd);

    [[NSUserDefaults standardUserDefaults] setInteger:pd->getSequenceForNextRequest() forKey:LDBClientSequenceProperty];
    
    if (pd->isComplete()) {
        notify(LDBSyncStatus_PULL_ENDED, nil);
        notify(LDBSyncStatus_OK, nil);
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/_lowla/pull", server];
    
    doPost(url, pullRequestBson, ^(id responseObject) {
        const char *json = (const char *)[((NSData *)responseObject) bytes];
        lowladb_apply_json_pull_response(json, pd);
        pullChunk(server, pd, notify);
    }, ^(NSError *error) {
        notify(LDBSyncStatus_PULL_ENDED, nil);
        notify(LDBSyncStatus_ERROR, [error localizedDescription]);
    });
}

static void pull(NSString *server, SyncNotifier notify) {
    notify(LDBSyncStatus_PULL_STARTED, nil);
    
    long currentSeq = [[NSUserDefaults standardUserDefaults] integerForKey:LDBClientSequenceProperty];
    
    NSString *url = [NSString stringWithFormat:@"%@/_lowla/changes?seq=%ld", server, currentSeq];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *data = (NSData *)responseObject;
        CLowlaDBBson::ptr responseBson = lowladb_json_to_bson((const char *)[data bytes], [data length]);
        if (responseBson) {
            CLowlaDBPullData::ptr pd = lowladb_parse_syncer_response(responseBson->data());
            pullChunk(server, pd, notify);
        }
        else {
            notify(LDBSyncStatus_PULL_ENDED, nil);
            notify(LDBSyncStatus_ERROR, @"Unable to parse syncer response");
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        notify(LDBSyncStatus_PULL_ENDED, nil);
        notify(LDBSyncStatus_ERROR, [error localizedDescription]);
    }];
}

static void pushChunk(NSString *server, CLowlaDBPushData::ptr pd, SyncNotifier notify) {
    if (pd->isComplete()) {
        notify(LDBSyncStatus_PUSH_ENDED, nil);
        pull(server, notify);
        return;
    }
    
    CLowlaDBBson::ptr pushRequestBson = lowladb_create_push_request(pd);

    NSString *url = [NSString stringWithFormat:@"%@/_lowla/push", server];
    doPost(url, pushRequestBson, ^(id responseObject) {
        const char *json = (const char *)[((NSData *)responseObject) bytes];
        lowladb_apply_json_push_response(json, pd);
        pushChunk(server, pd, notify);
    }, ^(NSError *error) {
        notify(LDBSyncStatus_PUSH_ENDED, nil);
        notify(LDBSyncStatus_ERROR, [error localizedDescription]);
    });
}

static void push(NSString *server, SyncNotifier notify) {
    notify(LDBSyncStatus_PUSH_STARTED, nil);
    
    CLowlaDBPushData::ptr pd = lowladb_collect_push_data();
    pushChunk(server, pd, notify);
}

@implementation LDBClient

+ (void)enableNotifications:(BOOL)enable
{
    if (enable) {
        lowladb_add_collection_listener(listener, nullptr);
    }
    else {
        lowladb_remove_collection_listener(listener);
    }
}

+ (void)sync:(NSString *)server notify:(SyncNotifier)notify
{
    push(server, notify);
}

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
