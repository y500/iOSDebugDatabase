//
//  DebugDatabaseResponse.h
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebugDatabaseResponse : NSObject

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, strong) NSData *contentData;

//for download file
@property (nonatomic, copy) NSString *fileName;

- (instancetype)initWithHtmlData:(NSData *)data contentType:(NSString*)contentType;
- (instancetype)initWithHtmlData:(NSData*)data;
- (instancetype)initWithFileName:(NSString*)fileName;
- (instancetype)initWithFilePath:(NSString*)path;

@end
