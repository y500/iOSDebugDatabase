//
//  DebugDatabaseManager.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/10.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "DebugDatabaseManager.h"
#import "NSURL+scheme.h"
#import "DatabaseUtil.h"
#import "NSString+json.h"
#ifdef COCOAPODS
#import <GCDWebServer/GCDWebServerRequest.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#else
#import <GCDWebServers/GCDWebServerRequest.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>
#endif


@interface DebugDatabaseManager ()<GCDWebServerDelegate>

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
        NSURL *bundleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Web" withExtension:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        
        [self addGETHandlerForBasePath:@"/" directoryPath:[bundle resourcePath] indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
        
        [self setupAdvanceRoutes];
    }
    return self;
}

- (void)setupAdvanceRoutes {
    
    __weak typeof(self)weakSelf = self;
    
    [self addHandlerForMethod:@"GET"
                         path:@"/databaseList"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     return [GCDWebServerDataResponse responseWithJSONObject:@{@"rows" : weakSelf.databasePaths.allKeys ?: [NSNull null]}];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/tableList"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *params = request.URL.queryParams;
                     NSString *dbName = [params objectForKey:@"database"];
                     [[DatabaseUtil shared] openDatabase:[weakSelf.databasePaths objectForKey:dbName]];
                     NSArray *array = [[DatabaseUtil shared] allTables];
                     [[DatabaseUtil shared] closeDatabase];
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:@{@"rows" : array?:[NSNull null]}];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/allTableRecords"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *params = request.URL.queryParams;
                     NSString *dbName = [params objectForKey:@"database"];
                     NSString *tableName = [params objectForKey:@"tableName"];
                     
                     [[DatabaseUtil shared] openDatabase:[weakSelf.databasePaths objectForKey:dbName]];
                     NSDictionary *rows = [[DatabaseUtil shared] rowsInTable:tableName];
                     [[DatabaseUtil shared] closeDatabase];
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:rows?:[NSNull null]];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/updateRecord"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *params = request.URL.queryParams;
                     NSString *dbName = [params objectForKey:@"database"];
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
                         
                         [[DatabaseUtil shared] openDatabase:yy_dicGetString(weakSelf.databasePaths, dbName)];
                         isSuccess = [[DatabaseUtil shared] updateRecordInDatabase:dbName tableName:tableName data:contentValues condition:where];
                         [[DatabaseUtil shared] closeDatabase];
                         
                     }
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:@{@"isSuccessful" : @(isSuccess)}];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/deleteRecord"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *params = request.URL.queryParams;
                     NSString *dbName = [params objectForKey:@"database"];
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
                         
                         [[DatabaseUtil shared] openDatabase:yy_dicGetString(weakSelf.databasePaths, dbName)];
                         isSuccess = [[DatabaseUtil shared] deleteRecordInDatabase:dbName tableName:tableName condition:where limit:nil];
                         [[DatabaseUtil shared] closeDatabase];
                         
                     }
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:@{@"isSuccessful" : @(isSuccess)}];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/query"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *params = request.URL.queryParams;
                     NSString *dbName = [params objectForKey:@"database"];
                     NSString *query = [yy_dicGetString(params, @"query") URLDecode];
                     NSString *tableName = [weakSelf getTableNameFromQuery:query];
                     NSString *operator = [weakSelf getOperatorFromQuery:query];
                     
                     [[DatabaseUtil shared] openDatabase:yy_dicGetString(weakSelf.databasePaths, dbName)];
                     NSDictionary *resultData = [[DatabaseUtil shared] executeQueryInDatabase:dbName tableName:tableName operator:operator query:query];
                     [[DatabaseUtil shared] closeDatabase];
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:resultData?:[NSNull null]];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/downloadDb"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSString *dbName = [request.URL.queryParams objectForKey:@"database"];
                     return [GCDWebServerDataResponse responseWithData:[NSData dataWithContentsOfFile:yy_dicGetString(weakSelf.databasePaths, dbName)] contentType:@"application/octet-stream"];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/getUserDefault"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSMutableDictionary *userData = [[DatabaseUtil shared] userDefaultData].mutableCopy;
                     
                     [userData safe_setObject:@YES forKey:@"userDefault"];
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:userData];
                 }];
    
    [self addHandlerForMethod:@"GET"
                         path:@"/getAppInfo"
                 requestClass:[GCDWebServerRequest class]
                 processBlock:^GCDWebServerResponse*(GCDWebServerRequest* request) {
                     
                     NSDictionary *appInfo = [[DatabaseUtil shared] getAppInfoData];
                     
                     return [GCDWebServerDataResponse responseWithJSONObject:appInfo];
                 }];
}

- (void)startServerOnPort:(NSInteger)port directories:(NSArray *)directories {
    
    _databasePaths = [self getAllDBPathsWithDirectories:directories];
    
    [self startWithPort:port bonjourName:@""];
    
    NSLog(@"Visit %@ in your web browser", self.serverURL);
    
}

- (void)startServerOnPort:(NSInteger)port {
    NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSString *documentDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    [self startServerOnPort:port directories:@[cacheDir, documentDir]];
}

- (NSDictionary*)getAllDBPathsWithDirectories:(NSArray*)directories {
    NSMutableDictionary *paths = @{}.mutableCopy;
    
    for (NSString *directory in directories) {
        NSArray *dirList = [[[NSFileManager defaultManager] subpathsAtPath:directory] pathsMatchingExtensions:[self databaseSuffixs]];
        
        for (NSString *subPath in dirList) {
            if ([self checkDatabaseFile:subPath]) {
                 [paths setObject:[directory stringByAppendingPathComponent:subPath] forKey:subPath.lastPathComponent];
            }
        }
        
        if ([self checkDatabaseFile:directory]) {
            [paths setObject:directory forKey:directory.lastPathComponent];
        }
    }
    
    return paths;
}

- (BOOL)checkDatabaseFile:(NSString*)fileName {
    for (NSString *suffix in [self databaseSuffixs]) {
        if ([fileName hasSuffix:suffix]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray*)databaseSuffixs {
    return @[@"sqlite", @"SQLITE", @"db", @"DB", @"sqlite3", @"SQLITE3"];
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
