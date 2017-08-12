//
//  DebugDatabaseResponse.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "DebugDatabaseResponse.h"

@interface DebugDatabaseResponse ()

@end

@implementation DebugDatabaseResponse

- (instancetype)initWithHtmlData:(NSData *)data contentType:(NSString*)contentType {
    self = [super init];
    if (self) {
        _statusCode = 200;
        _contentType = contentType;
        
        if (_fileName.length > 0) {
            NSMutableString *res = [NSMutableString string];
            [res appendString:[NSString stringWithFormat:@"HTTP/1.0 %zd\n",_statusCode]];
            [res appendString:@"Accept-Ranges:bytes\n"];
            [res appendString:[NSString stringWithFormat:@"Content-Type: %@; charset=UTF-8\n",self.contentType?:@"text/html"]];
            [res appendString:[NSString stringWithFormat:@"Content-Length:%zd\n",data.length]];
            [res appendString:[NSString stringWithFormat:@"Content-Disposition: attachment; filename=%@\n",self.fileName]];
            [res appendString:@"\n"];
            
            NSMutableData *resultData = [[res dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            [resultData appendData:data];
            _contentData = [NSData dataWithData:resultData];
        }else {
            NSMutableString *res = [NSMutableString string];
            [res appendString:[NSString stringWithFormat:@"HTTP/1.0 %zd\n",_statusCode]];
            [res appendString:@"Accept-Ranges:bytes\n"];
            [res appendString:[NSString stringWithFormat:@"Content-Type: %@; charset=UTF-8\n",self.contentType?:@"text/html"]];
            [res appendString:[NSString stringWithFormat:@"Content-Length:%zd\n",data.length]];
            [res appendString:@"\n"];
            [res appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            
            NSMutableData *resultData = [[res dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            _contentData = [NSData dataWithData:resultData];
            
        }
    }
    
    return self;
}

- (instancetype)initWithHtmlData:(NSData *)data {
    return [self initWithHtmlData:data contentType:@"text/html"];
}

- (instancetype)initWithFileName:(NSString *)fileName {
    NSString *contentType = [[self class] detectMimeType:fileName];
    NSData *data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName]];
    return [self initWithHtmlData:data contentType:contentType];
}

- (instancetype)initWithFilePath:(NSString *)path {
    _fileName = path.lastPathComponent;
    NSString *contentType = [[self class] detectMimeType:path];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithHtmlData:data contentType:contentType];
}

+ (NSString*)detectMimeType:(NSString *)fileName{
    if (fileName.length==0) {
        return nil;
    } else if ([fileName hasSuffix:@".html"]) {
        return @"text/html";
    } else if ([fileName hasSuffix:@".js"]) {
        return @"application/javascript";
    } else if ([fileName hasSuffix:@".css"]) {
        return @"text/css";
    } else {
        return @"application/octet-stream";
    }
}

@end
