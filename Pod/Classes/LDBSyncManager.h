//
//  LDBSyncManager.h
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#import <Foundation/Foundation.h>

@protocol LDBSyncDelegate <NSObject>
- (BOOL)syncWillBeginPull;
- (void)syncDidEndPull;
@end


@interface LDBSyncManager : NSObject

@property BOOL enableBackgroundSync;
@property (weak) id<LDBSyncDelegate> delegate;

+ (LDBSyncManager *)sharedManager;
@end
