//
//  DatabaseUtil.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "DatabaseUtil.h"
#import <sqlite3.h>

#ifdef COCOAPODS
#import "FMDB.h"
#else
#import <FMDB/FMDB.h>
#endif



@interface DatabaseUtil ()

@property(nonatomic) sqlite3 *db;
@property(nonatomic, ) NSString *dbPath;
@property(nonatomic, copy) NSString *dbName;
@property(nonatomic, strong) FMDatabase *fmdb;

@end

@implementation DatabaseUtil

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static DatabaseUtil *dbUtil;
    dispatch_once(&onceToken, ^{
        dbUtil = [[self alloc] init];
    });
    return dbUtil;
}

- (BOOL)openDatabase:(NSString*)dbPath {
    
    if (self.dbPath && _db && ![dbPath isEqualToString:self.dbPath]){
        [self closeDatabase];
    }
    
    _dbPath = dbPath;
    _dbName = [_dbPath lastPathComponent];
    
    NSString *dbDir = [_dbPath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbDir]) {
        return NO;
    }
    
    self.fmdb = [FMDatabase databaseWithPath:dbPath];
    
    if (![self.fmdb open]) {
        NSLog(@"Could not open db %@.", dbPath);
        return NO;
    }
    
    return YES;
    
}

- (BOOL)closeDatabase {
    if (self.fmdb != nil){
        [self.fmdb close];
    }
    
    return YES;
}

- (NSArray*)allTables {
    
    NSString *sql = @"SELECT tbl_name FROM sqlite_master WHERE type = 'table'";
    FMResultSet *rs = [self.fmdb executeQuery:sql];
    
    NSMutableArray *tables = @[].mutableCopy;
    
    while ([rs next]) {
        [tables safe_addObject:[rs stringForColumn:@"tbl_name"]];
    }
    
    return tables;
}

- (NSArray*)tableInfo:(NSString*)tableName {
    FMResultSet *rs = [self.fmdb getTableSchema:tableName];
    
    NSMutableArray *infos = @[].mutableCopy;
    
    while ([rs next]) {
        [infos safe_addObject:rs.resultDictionary?:[NSNull null]];
    }
    return infos;
}

- (NSDictionary*)rowsInTable:(NSString*)tableName {
    
    NSMutableDictionary *tableData = [NSMutableDictionary dictionary];
    [tableData safe_setObject:@(1) forKey:@"isSelectQuery"];
    [tableData safe_setObject:@(1) forKey:@"isSuccessful"];
    
    //标题
    FMResultSet *infors = [self.fmdb getTableSchema:tableName];
    
    NSMutableArray *tableInfoResult = [NSMutableArray array];
    
    NSMutableArray *columnKeys = [NSMutableArray arrayWithCapacity:10];
    
    while ([infors next]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info safe_setObject:@([infors boolForColumn:@"pk"]) forKey:@"isPrimary"];
        [info safe_setObject:[NSString stringWithFormat:@"%@[%@]", [infors stringForColumn:@"name"]?:@"", [infors stringForColumn:@"type"]]  forKey:@"title"];
        [info safe_setObject:[infors stringForColumn:@"type"] forKey:@"dataType"];
        [tableInfoResult safe_addObject:info];
        
        [columnKeys addObject:[infors stringForColumn:@"name"]?:@""];
    }
    [tableData safe_setObject:tableInfoResult forKey:@"tableInfos"];
    
    BOOL isEditable = tableName != nil && [tableData objectForKey:@"tableInfos"] != nil;
    [tableData safe_setObject:@(isEditable) forKey:@"isEditable"];
    
    
    //数据
    NSString *sql = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *rs = [self.fmdb executeQuery:sql];
    NSMutableArray *rows = @[].mutableCopy;
    
    while ([rs next]) {
        NSMutableArray *row = @[].mutableCopy;
        
        for ( int i = 0; i < tableInfoResult.count; i++) {
            NSMutableDictionary *columnData = [NSMutableDictionary dictionaryWithCapacity:10];
            NSString *columName = [columnKeys objectAtIndex:i];
            NSString *type = [[tableInfoResult objectAtIndex:i] objectForKey:@"dataType"];
            
            if ([[type lowercaseString] isEqualToString:@"integer"]) {
                [columnData safe_setObject:@"integer" forKey:@"dataType"];
            }else if ([[type lowercaseString] isEqualToString:@"real"]) {
                [columnData safe_setObject:@"float" forKey:@"dataType"];
            }else if ([[type lowercaseString] isEqualToString:@"text"]) {
                [columnData safe_setObject:@"text" forKey:@"dataType"];
            }else if ([[type lowercaseString] isEqualToString:@"blob"]) {
                [columnData safe_setObject:@"blob" forKey:@"dataType"];
            }else if ([[type lowercaseString] isEqualToString:@"null"]) {
                [columnData safe_setObject:@"null" forKey:@"dataType"];
            }else {
                [columnData safe_setObject:@"text" forKey:@"dataType"];
            }
            
            if ([[type lowercaseString] isEqualToString:@"blob"]) {
                [columnData safe_setObject:@"blob" forKey:@"value"];
            }else if ([[type lowercaseString] isEqualToString:@"guid"]){
                
                
                id data = [rs respondsToSelector:@selector(objectForColumn:)] ? [rs performSelector:@selector(objectForColumn:) withObject:columName] : [rs performSelector:@selector(objectForColumnName:) withObject:columName];
                const unsigned char *bytes = (const unsigned char *)[data bytes];
                NSMutableString *hex = [NSMutableString new];
                for (NSInteger i = 0; i < [data length]; i++) {
                    [hex appendFormat:@"%02x", bytes[i]];
                }
                
                [columnData safe_setObject:hex?:[NSNull null] forKey:@"value"];
            }else {
                id obj = [rs respondsToSelector:@selector(objectForColumn:)] ? [rs performSelector:@selector(objectForColumn:) withObject:columName] : [rs performSelector:@selector(objectForColumnName:) withObject:columName];
                [columnData safe_setObject:obj?:[NSNull null] forKey:@"value"];
            }
            
            
            
            [row safe_addObject:columnData];
        }
        
        [rows safe_addObject:row];
    }
    
    [tableData safe_setObject:rows forKey:@"rows"];
    return tableData;
}

- (BOOL)updateRecordInDatabase:(NSString *)database tableName:(NSString *)tableName data:(NSDictionary *)data condition:(NSDictionary *)condition {
    
    NSMutableArray *fields = @[].mutableCopy;
    
    for (NSString *key in data.allKeys) {
        [fields safe_addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [data objectForKey:key]]];
    }
    NSString *values = [fields componentsJoinedByString:@","];
    
    NSString *where = @"1";
    
    if ([condition isKindOfClass:[NSDictionary class]] && condition.count > 0) {
        NSMutableArray *conArray = @[].mutableCopy;
        
        for (NSString *key in condition.allKeys) {
            [conArray safe_addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [condition objectForKey:key]]];
        }
        
        where = [conArray componentsJoinedByString:@" AND "];
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE \"%@\" SET %@ WHERE %@",tableName,values,where];
    return [self.fmdb executeQuery:sqlString];    
}

- (BOOL)deleteRecordInDatabase:(NSString *)database tableName:(NSString *)tableName condition:(NSDictionary *)condition limit:(NSString *)limit {
    NSString *where = @"1";
    NSString *limitString =@"";
    if (limit.length > 0) {
        limitString = [NSString stringWithFormat:@"LIMIT %@",limit];
    }
    
    if ([condition isKindOfClass:[NSDictionary class]] && condition.count > 0) {
        NSMutableArray *conArray = @[].mutableCopy;
        
        for (NSString *key in condition.allKeys) {
            [conArray safe_addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [condition objectForKey:key]]];
        }
        
        where = [conArray componentsJoinedByString:@" AND "];
    }
    
    NSString *sqlString =[NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE %@ %@",tableName,where,limitString];
    NSLog(@"delete %@",sqlString);
    return [self.fmdb executeUpdate:sqlString];
}

- (NSDictionary*)executeQueryInDatabase:(NSString*)database tableName:(NSString*)tableName operator:(NSString*)operator query:(NSString*)query {
    
    if ([operator isEqualToString:@"select"]) {
        
        NSMutableDictionary *tableData = [NSMutableDictionary dictionary];
        [tableData safe_setObject:@(1) forKey:@"isSelectQuery"];
        [tableData safe_setObject:@(1) forKey:@"isSuccessful"];
        
        
        //数据
        NSString *sql = query;
        FMResultSet *rs = [self.fmdb executeQuery:sql];
        NSMutableArray *rows = @[].mutableCopy;
        
        //标题
        FMResultSet *infors = [self.fmdb getTableSchema:tableName];
        
        NSMutableArray *tableInfoResult = [NSMutableArray array];
        
        while ([infors next]) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            
            NSString *columnName = [infors stringForColumn:@"name"];
            
            if ([rs.columnNameToIndexMap.allKeys containsObject:columnName]) {
                [info safe_setObject:@([infors boolForColumn:@"pk"]) forKey:@"isPrimary"];
                [info safe_setObject:[infors stringForColumn:@"name"]?:@"" forKey:@"title"];
                [info safe_setObject:[infors stringForColumn:@"type"] forKey:@"dataType"];
                [tableInfoResult safe_addObject:info];
            }
        }
        [tableData safe_setObject:tableInfoResult forKey:@"tableInfos"];
        
        BOOL isEditable = tableName != nil && [tableData objectForKey:@"tableInfos"] != nil;
        [tableData safe_setObject:@(isEditable) forKey:@"isEditable"];
        
        while ([rs next]) {
            NSMutableArray *row = @[].mutableCopy;
            
            for ( int i = 0; i < tableInfoResult.count; i++) {
                NSMutableDictionary *columnData = [NSMutableDictionary dictionaryWithCapacity:10];
                NSString *columName = [[tableInfoResult objectAtIndex:i] objectForKey:@"title"];
                NSString *type = [[tableInfoResult objectAtIndex:i] objectForKey:@"dataType"];
                
                if ([[type lowercaseString] isEqualToString:@"integer"]) {
                    [columnData safe_setObject:@"integer" forKey:@"dataType"];
                    [columnData safe_setObject:@([rs intForColumn:columName]) forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"real"]) {
                    [columnData safe_setObject:@"float" forKey:@"dataType"];
                    [columnData safe_setObject:@([rs doubleForColumn:columName]) forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"text"]) {
                    [columnData safe_setObject:@"text" forKey:@"dataType"];
                    [columnData safe_setObject:[rs stringForColumn:columName]?:@"" forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"blob"]) {
                    [columnData safe_setObject:@"blob" forKey:@"dataType"];
                    [columnData safe_setObject:@"blob" forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"null"]) {
                    [columnData safe_setObject:@"null" forKey:@"dataType"];
                    [columnData safe_setObject:[NSNull null] forKey:@"value"];
                }else {
                    [columnData safe_setObject:@"text" forKey:@"dataType"];
                    [columnData safe_setObject:[rs stringForColumn:columName] forKey:@"value"];
                }
                
                [row safe_addObject:columnData];
            }
            
            [rows safe_addObject:row];
        }
        
        [tableData safe_setObject:rows forKey:@"rows"];
        return tableData;
        
    }else {
        BOOL result =  [self.fmdb executeUpdate:query];
        NSDictionary *respone;
        if (result) {
            respone = @{@"isSelectQuery":@(true),@"isSuccessful":@(true)};
        }else{
            respone = @{@"isSelectQuery":@(true),@"isSuccessful":@(false),@"errorMessage":@"Database Opration faild!"};
        }
        
        return respone;
    }
}

- (NSDictionary*)userDefaultData {
    
    NSMutableDictionary *tableData = [NSMutableDictionary dictionary];
    [tableData safe_setObject:@(1) forKey:@"isSelectQuery"];
    [tableData safe_setObject:@(1) forKey:@"isSuccessful"];
    
    NSMutableArray *tableInfoResult = [NSMutableArray array];
    [tableInfoResult safe_addObject:@{@"title": @"key", @"isPrimary" : @(1), @"dataType" : @"text"}];
    [tableInfoResult safe_addObject:@{@"title": @"value", @"isPrimary" : @(0), @"dataType" : @"text"}];
    
    [tableData safe_setObject:tableInfoResult forKey:@"tableInfos"];
    
    [tableData safe_setObject:@(NO) forKey:@"isEditable"];
    
    NSMutableArray *rows = @[].mutableCopy;
    
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults]dictionaryRepresentation];
    
    for (NSString *key in userData.allKeys) {
        NSMutableArray *row = @[].mutableCopy;
        
        [row safe_addObject:@{@"dataType" : @"text", @"value" : key?key:@""}];
        
        id value = [userData objectForKey:key];
        
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            [row safe_addObject:@{@"dataType" : @"text", @"value" : yy_dicGetStringSafe(userData, key)}];
        }else {
            [row safe_addObject:@{@"dataType" : @"text", @"value" : [value description]?:@""}];
        }
        
        [rows addObject:row];
    }
    [tableData safe_setObject:rows forKey:@"rows"];
    
    return tableData;
}

- (NSDictionary*)getAppInfoData {
    NSMutableDictionary *tableData = [NSMutableDictionary dictionary];
    [tableData safe_setObject:@(1) forKey:@"isSelectQuery"];
    [tableData safe_setObject:@(1) forKey:@"isSuccessful"];
    
    NSMutableArray *tableInfoResult = [NSMutableArray array];
    [tableInfoResult safe_addObject:@{@"title": @"property name", @"isPrimary" : @(1), @"dataType" : @"text"}];
    [tableInfoResult safe_addObject:@{@"title": @"property value", @"isPrimary" : @(0), @"dataType" : @"text"}];
    
    [tableData safe_setObject:tableInfoResult forKey:@"tableInfos"];
    
    [tableData safe_setObject:@(NO) forKey:@"isEditable"];
    
    NSMutableArray *rows = @[].mutableCopy;
    
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    //app name
    NSString *displayName = yy_dicGetStringSafe(infoDic, @"CFBundleDisplayName");
    NSMutableArray *displayRow = @[].mutableCopy;
    [displayRow safe_addObject:@{@"dataType": @"text", @"value": @"Display Name"}];
    [displayRow safe_addObject:@{@"dataType": @"text", @"value": displayName}];
    [rows safe_addObject:displayRow];
    
    //app bundle identifier
    NSString *bundleIdentifer = yy_dicGetStringSafe(infoDic, kCFBundleIdentifierKey);
    NSMutableArray *bundleRow = @[].mutableCopy;
    [bundleRow safe_addObject:@{@"dataType": @"text", @"value": @"Bundle Identifer"}];
    [bundleRow safe_addObject:@{@"dataType": @"text", @"value": bundleIdentifer}];
    [rows safe_addObject:bundleRow];
    
    //app version
    NSString *version = yy_dicGetStringSafe(infoDic, @"CFBundleShortVersionString");
    NSMutableArray *versionRow = @[].mutableCopy;
    [versionRow safe_addObject:@{@"dataType": @"text", @"value": @"Version"}];
    [versionRow safe_addObject:@{@"dataType": @"text", @"value": version}];
    [rows safe_addObject:versionRow];
    
    //app build number
    NSString *build = yy_dicGetStringSafe(infoDic, kCFBundleVersionKey);
    NSMutableArray *buildRow = @[].mutableCopy;
    [buildRow safe_addObject:@{@"dataType": @"text", @"value": @"Build"}];
    [buildRow safe_addObject:@{@"dataType": @"text", @"value": build}];
    [rows safe_addObject:buildRow];
    
    //document path
    NSArray *pathSearch = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [pathSearch objectAtIndex:0];
    NSMutableArray *documentRow = @[].mutableCopy;
    [documentRow safe_addObject:@{@"dataType": @"text", @"value": @"Documents"}];
    [documentRow safe_addObject:@{@"dataType": @"text", @"value": documentsPath?documentsPath:@""}];
    [rows safe_addObject:documentRow];
    
    //cache path
    NSArray *pathSearchCache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [pathSearchCache objectAtIndex:0];
    NSMutableArray *cacheRow = @[].mutableCopy;
    [cacheRow safe_addObject:@{@"dataType": @"text", @"value": @"Cache"}];
    [cacheRow safe_addObject:@{@"dataType": @"text", @"value": cachePath?cachePath:@""}];
    [rows safe_addObject:cacheRow];
    
    [tableData safe_setObject:rows forKey:@"rows"];
    
    return tableData;
}

@end
