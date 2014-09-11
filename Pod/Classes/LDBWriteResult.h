//
//  LDBWriteResult.h
//  lowladb-objc
//
//  Created by mark on 7/8/14.
//
//

#import <Foundation/Foundation.h>

@class LDBObjectId;

@interface LDBWriteResult : NSObject
@property (readonly) LDBObjectId *upsertedId;

@end
