//
//  DebugDatabaseManager.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/10.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "DebugDatabaseManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "DebugDatabaseRequest.h"
#import "DebugDatabaseResponse.h"
#import "NSURL+scheme.h"
#import "DatabaseUtil.h"
#import "NSString+json.h"

@interface DebugDatabaseManager ()<GCDAsyncSocketDelegate>

@property(nonatomic, strong) GCDAsyncSocket *webServer;
@property(nonatomic, strong) GCDAsyncSocket *connectedSocket;
@property(nonatomic, copy) NSString *host;
@property(nonatomic, assign) NSInteger port;
@property(nonatomic, strong) NSDictionary *databasePaths;


@end

@implementation DebugDatabaseManager

+ (instancetype)shared {
    static dispatch_once_t oneceToken;
    static DebugDatabaseManager *debugDatabaseManager;
    dispatch_once(&oneceToken, ^{
        debugDatabaseManager = [[DebugDatabaseManager alloc] init];
    });
    return debugDatabaseManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.webServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)startServerOnPort:(NSInteger)port directories:(NSArray *)directories {
    _port = port;
    
    _databasePaths = [self getAllDBPathsWithDirectories:directories];
    
    NSError *error;
    
    self.webServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if ([_webServer acceptOnPort:_port error:&error]) {
        NSLog(@"server start on %@:%zd",_webServer.localHost,_webServer.localPort);
        _host = _webServer.localHost;
    }else{
        NSLog(@"error %@",error);
    }
}

- (void)startServerOnPort:(NSInteger)port {
    NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSString *documentDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    [self startServerOnPort:port directories:@[cacheDir, documentDir]];
}

#pragma mark GCDAsyncSocket delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port {
    NSLog(@"didConnectToHost:%@ %zd", host, port);
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"didAcceptNewSocket");
    NSLog(@"newSocket %@ %zd", newSocket.localHost, newSocket.localPort);
    _connectedSocket = newSocket;
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"didReadData");
    NSLog(@"sock %@ %zd", sock.localHost, sock.localPort);
    DebugDatabaseRequest *request = [DebugDatabaseRequest debugDatabaseRequestWithData:data];
    
    //处理每一个request
    NSURL * url = [NSURL URLWithString:request.path];
    
    //根目录
    if ([url.path isEqualToString:@"/"]) {
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithFileName:@"index.html"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //资源文件
    else if ([url.path hasSuffix:@".html"] || [url.path hasSuffix:@".css"] || [url.path hasSuffix:@".js"] || [url.path hasSuffix:@".png"] || [url.path hasSuffix:@".jpg"]) {
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithFileName:url.path];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //获取数据库列表
    else if ([url.path isEqualToString:@"/databaseList"]) {
        NSDictionary *databases = @{@"rows" : _databasePaths.allKeys ?: [NSNull null]};
        NSData *data = [[self mapOrArrayTransformToJsonString:databases] dataUsingEncoding:NSUTF8StringEncoding];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:data contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //获取某个数据库的所有表
    else if ([url.path isEqualToString:@"/tableList"]) {
        NSDictionary *params = url.queryParams;
        NSString *dbName = [params objectForKey:@"database"];
        [[DatabaseUtil shared] openDatabase:[_databasePaths objectForKey:dbName]];
        NSArray *array = [[DatabaseUtil shared] allTables];
        [[DatabaseUtil shared] closeDatabase];
        
        NSData *data = [[self mapOrArrayTransformToJsonString:@{@"rows" : array?:[NSNull null]}] dataUsingEncoding:NSUTF8StringEncoding];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:data contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //获取某个表中所有记录
    else if ([url.path isEqualToString:@"/allTableRecords"]) {
        NSDictionary *params = url.queryParams;
        NSString *dbName = [params objectForKey:@"database"];
        NSString *tableName = [params objectForKey:@"tableName"];
        
        [[DatabaseUtil shared] openDatabase:[_databasePaths objectForKey:dbName]];
        NSDictionary *rows = [[DatabaseUtil shared] rowsInTable:tableName];
        [[DatabaseUtil shared] closeDatabase];
        
        NSData *data = [[self mapOrArrayTransformToJsonString:rows?:[NSNull null]] dataUsingEncoding:NSUTF8StringEncoding];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:data contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //更新某条记录
    else if ([url.path isEqualToString:@"/updateRecord"]) {
        NSDictionary *params = url.queryParams;
        NSString *dbName = [params objectForKey:@"dbName"];
        NSString *tableName = [params objectForKey:@"tableName"];
        
        NSDictionary *updateData =[[yy_dicGetString(params, @"updatedData") URLDecode] JSONObject];
        
        BOOL isSuccess;
        
        if (updateData.count == 0 || dbName.length == 0 || tableName.length == 0) {
            isSuccess = NO;
        }else {
            NSMutableDictionary *contentValues = [NSMutableDictionary dictionary];
            NSMutableDictionary *where = [NSMutableDictionary dictionary];
            for (NSDictionary *columnDic in updateData) {
                if (yy_dicGetBool(columnDic, @"isPrimary", NO)) {
                    [where setObject:[columnDic objectForKey:@"value"]?:[NSNull null] forKey:yy_dicGetStringSafe(columnDic, @"title")];
                } else {
                    [contentValues setObject:[columnDic objectForKey:@"value"]?:[NSNull null] forKey:[columnDic objectForKey:@"title"]];
                }
            }
            
            [[DatabaseUtil shared] openDatabase:yy_dicGetString(_databasePaths, dbName)];
            isSuccess = [[DatabaseUtil shared] updateRecordInDatabase:dbName tableName:tableName data:contentValues condition:where];
            [[DatabaseUtil shared] closeDatabase];
            
        }
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:[[self mapOrArrayTransformToJsonString:@{@"isSuccessful" : @(isSuccess)}] dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //删除某条记录
    else if ([url.path isEqualToString:@"/deleteRecord"]) {
        NSDictionary *params = url.queryParams;
        NSString *dbName = [params objectForKey:@"dbName"];
        NSString *tableName = [params objectForKey:@"tableName"];
        
        NSDictionary *deleteData =[[yy_dicGetString(params, @"deleteData") URLDecode] JSONObject];
        
        BOOL isSuccess;
        
        if (deleteData.count == 0 || dbName.length == 0 || tableName.length == 0) {
            isSuccess = NO;
        }else {
            NSMutableDictionary *where = [NSMutableDictionary dictionary];
            for (NSDictionary *columnDic in deleteData) {
                if (yy_dicGetBool(columnDic, @"isPrimary", NO)) {
                    [where setObject:[columnDic objectForKey:@"value"]?:[NSNull null] forKey:yy_dicGetStringSafe(columnDic, @"title")];
                }
            }
            
            [[DatabaseUtil shared] openDatabase:yy_dicGetString(_databasePaths, dbName)];
            isSuccess = [[DatabaseUtil shared] deleteRecordInDatabase:dbName tableName:tableName condition:where limit:nil];
            [[DatabaseUtil shared] closeDatabase];
            
        }
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:[[self mapOrArrayTransformToJsonString:@{@"isSuccessful" : @(isSuccess)}] dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];

        
    }
    //条件查询
    else if ([url.path isEqualToString:@"/query"]) {
        NSDictionary *params = url.queryParams;
        NSString *dbName = [params objectForKey:@"database"];
        NSString *query = [yy_dicGetString(params, @"query") URLDecode];
        NSString *tableName = [self getTableNameFromQuery:query];
        NSString *operator = [self getOperatorFromQuery:query];
        
        [[DatabaseUtil shared] openDatabase:yy_dicGetString(_databasePaths, dbName)];
        NSDictionary *resultData = [[DatabaseUtil shared] executeQueryInDatabase:dbName tableName:tableName operator:operator query:query];
        [[DatabaseUtil shared] closeDatabase];
        
        NSData *data = [[self mapOrArrayTransformToJsonString:resultData?:[NSNull null]] dataUsingEncoding:NSUTF8StringEncoding];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:data contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    else if ([url.path isEqualToString:@"/downloadDb"]) {
        NSString *dbName = [url.queryParams objectForKey:@"database"];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithFilePath:yy_dicGetString(_databasePaths, dbName)];
        response.contentType = @"application/octet-stream";
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    else if ([url.path isEqualToString:@"/getUserDefault"]) {
        NSMutableDictionary *userData = [[DatabaseUtil shared] userDefaultData].mutableCopy;
        
        [userData safe_setObject:@YES forKey:@"userDefault"];
        
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:[[self mapOrArrayTransformToJsonString:userData] dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    else if ([url.path isEqualToString:@"/getAppInfo"]) {
        NSDictionary *appInfo = [[DatabaseUtil shared] getAppInfoData];
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:[[self mapOrArrayTransformToJsonString:appInfo] dataUsingEncoding:NSUTF8StringEncoding] contentType:@"application/json"];
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
    //404 not found
    else {
        DebugDatabaseResponse *response = [[DebugDatabaseResponse alloc] initWithHtmlData:[@"404" dataUsingEncoding:NSUTF8StringEncoding]];
        response.statusCode = 404;
        [sock writeData:response.contentData withTimeout:-1 tag:0];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socketDidDisconnect:%@", err?err:@"");
}

- (NSDictionary*)getAllDBPathsWithDirectories:(NSArray*)directories {
    NSMutableDictionary *paths = @{}.mutableCopy;
    
    for (NSString *directory in directories) {
        NSArray *dirList = [[[NSFileManager defaultManager] subpathsAtPath:directory] pathsMatchingExtensions:@[@"sqlite",@"SQLITE",@"db",@"DB"]];
        
        for (NSString *subPath in dirList) {
            if ([subPath hasSuffix:@"sqlite"] || [subPath hasSuffix:@"SQLITE"]|| [subPath hasSuffix:@"db"]|| [subPath hasSuffix:@"DB"]) {
                [paths setObject:[directory stringByAppendingPathComponent:subPath] forKey:subPath.lastPathComponent];
            }
        }
        
        if ([directory hasSuffix:@"sqlite"] || [directory hasSuffix:@"SQLITE"]|| [directory hasSuffix:@"db"]|| [directory hasSuffix:@"DB"]) {
            [paths setObject:directory forKey:directory.lastPathComponent];
        }
    }
    
    return paths;
}

- (NSString*)mapOrArrayTransformToJsonString:(NSObject*)obj {
    if(obj == nil)
        return  nil;
    if (![obj isKindOfClass:[NSDictionary class]] && ![obj isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString*)getTableNameFromQuery:(NSString*)query {
    NSArray *words = [query  componentsSeparatedByString:@" "];
    NSString *operator = [[words firstObject] lowercaseString];
    NSInteger fromIndex = 0;
    NSString *table;

    for (int i =0;i<[words count];i++) {
        NSString *word = [words objectAtIndex:i];
        if ([operator isEqualToString:@"select"] || [operator isEqualToString:@"delete"]) {
            if ([word isEqualToString:@"from"]) {
                fromIndex = i;
            }
            if (i == fromIndex+1) {
                if([word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length==0){
                    fromIndex ++;
                }else{
                    table = word;
                }
            }
        }else if ([operator isEqualToString:@"update"]) {
            if ([word isEqualToString:@"update"]) {
                fromIndex = i;
            }
            if (i == fromIndex+1) {
                if([word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length==0){
                    fromIndex ++;
                }else{
                    table = word;
                }
            }
        }
    }
    return table;
}

- (NSString*)getOperatorFromQuery:(NSString*)query {
    NSArray *words = [query  componentsSeparatedByString:@" "];
    NSString *operator = [[words firstObject] lowercaseString];
    
    return operator;
}

@end
