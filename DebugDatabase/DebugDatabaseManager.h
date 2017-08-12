//
//  DebugDatabaseManager.h
//  YYDebugDatabase
//
//  Created by wentian on 17/8/10.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebugDatabaseManager : NSObject

+ (instancetype)shared;

- (void)startServerOnport:(NSInteger)port directories:(NSArray*)directories;

- (NSString*)mapOrArrayTransformToJsonString:(NSObject*)obj;

@end
