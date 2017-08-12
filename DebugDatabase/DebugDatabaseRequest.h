//
//  DebugDatabaseRequest.h
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebugDatabaseRequest : NSObject

@property (nonatomic,copy) NSMutableDictionary <NSString*,NSString*> *headers;
@property (nonatomic,copy) NSString *method;
@property (nonatomic,copy) NSString *path;
@property (nonatomic,copy) NSString *HTTPVersion;
- (instancetype)initWithData:(NSData*)data;

+ (instancetype)debugDatabaseRequestWithData:(NSData*)data;

@end
