//
//  DatabaseUtil.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "DatabaseUtil.h"
#import <sqlite3.h>
#import "FMDB.h"

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
        [tables addObject:[rs stringForColumn:@"tbl_name"]];
    }
    
    return tables;
}

- (NSArray*)tableInfo:(NSString*)tableName {
    FMResultSet *rs = [self.fmdb getTableSchema:tableName];
    
    NSMutableArray *infos = @[].mutableCopy;
    
    while ([rs next]) {
        [infos addObject:rs.resultDictionary?:[NSNull null]];
    }
    return infos;
}

- (NSDictionary*)rowsInTable:(NSString*)tableName {
    
    NSMutableDictionary *tableData = [NSMutableDictionary dictionary];
    [tableData setObject:@(1) forKey:@"isSelectQuery"];
    [tableData setObject:@(1) forKey:@"isSuccessful"];
    
    //标题
    FMResultSet *infors = [self.fmdb getTableSchema:tableName];
    
    NSMutableArray *tableInfoResult = [NSMutableArray array];
    
    while ([infors next]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:@([infors boolForColumn:@"pk"]) forKey:@"isPrimary"];
        [info setObject:[infors stringForColumn:@"name"]?:@"" forKey:@"title"];
        [info setObject:[infors stringForColumn:@"type"] forKey:@"dataType"];
        [tableInfoResult addObject:info];
    }
    [tableData setObject:tableInfoResult forKey:@"tableInfos"];
    
    BOOL isEditable = tableName != nil && [tableData objectForKey:@"tableInfos"] != nil;
    [tableData setObject:@(isEditable) forKey:@"isEditable"];
    
    
    //数据
    NSString *sql = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *rs = [self.fmdb executeQuery:sql];
    NSMutableArray *rows = @[].mutableCopy;
    
    while ([rs next]) {
        NSMutableArray *row = @[].mutableCopy;
        
        for ( int i = 0; i < tableInfoResult.count; i++) {
            NSMutableDictionary *columnData = [NSMutableDictionary dictionaryWithCapacity:10];
            NSString *columName = [[tableInfoResult objectAtIndex:i] objectForKey:@"title"];
            NSString *type = [[tableInfoResult objectAtIndex:i] objectForKey:@"dataType"];
            
            if ([[type lowercaseString] isEqualToString:@"integer"]) {
                [columnData setObject:@"integer" forKey:@"dataType"];
                [columnData setObject:@([rs intForColumn:columName]) forKey:@"value"];
            }else if ([[type lowercaseString] isEqualToString:@"real"]) {
                [columnData setObject:@"float" forKey:@"dataType"];
                [columnData setObject:@([rs doubleForColumn:columName]) forKey:@"value"];
            }else if ([[type lowercaseString] isEqualToString:@"text"]) {
                [columnData setObject:@"text" forKey:@"dataType"];
                [columnData setObject:[rs stringForColumn:columName]?:@"" forKey:@"value"];
            }else if ([[type lowercaseString] isEqualToString:@"blob"]) {
                [columnData setObject:@"blob" forKey:@"dataType"];
                [columnData setObject:@"blob" forKey:@"value"];
            }else if ([[type lowercaseString] isEqualToString:@"null"]) {
                [columnData setObject:@"null" forKey:@"dataType"];
                [columnData setObject:[NSNull null] forKey:@"value"];
            }else {
                [columnData setObject:@"text" forKey:@"dataType"];
                [columnData setObject:[rs stringForColumn:columName] forKey:@"value"];
            }
            
            [row addObject:columnData];
        }
        
        [rows addObject:row];
    }
    
    [tableData setObject:rows forKey:@"rows"];
    return tableData;
}

- (BOOL)updateRecordInDatabase:(NSString *)database tableName:(NSString *)tableName data:(NSDictionary *)data condition:(NSDictionary *)condition {
    
    NSMutableArray *fields = @[].mutableCopy;
    
    for (NSString *key in data.allKeys) {
        [fields addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [data objectForKey:key]]];
    }
    NSString *values = [fields componentsJoinedByString:@","];
    
    NSString *where = @"1";
    
    if ([condition isKindOfClass:[NSDictionary class]] && condition.count > 0) {
        NSMutableArray *conArray = @[].mutableCopy;
        
        for (NSString *key in condition.allKeys) {
            [conArray addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [condition objectForKey:key]]];
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
            [conArray addObject:[NSString stringWithFormat:@"%@ = '%@'", key, [condition objectForKey:key]]];
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
        [tableData setObject:@(1) forKey:@"isSelectQuery"];
        [tableData setObject:@(1) forKey:@"isSuccessful"];
        
        
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
                [info setObject:@([infors boolForColumn:@"pk"]) forKey:@"isPrimary"];
                [info setObject:[infors stringForColumn:@"name"]?:@"" forKey:@"title"];
                [info setObject:[infors stringForColumn:@"type"] forKey:@"dataType"];
                [tableInfoResult addObject:info];
            }
        }
        [tableData setObject:tableInfoResult forKey:@"tableInfos"];
        
        BOOL isEditable = tableName != nil && [tableData objectForKey:@"tableInfos"] != nil;
        [tableData setObject:@(isEditable) forKey:@"isEditable"];
        
        while ([rs next]) {
            NSMutableArray *row = @[].mutableCopy;
            
            for ( int i = 0; i < tableInfoResult.count; i++) {
                NSMutableDictionary *columnData = [NSMutableDictionary dictionaryWithCapacity:10];
                NSString *columName = [[tableInfoResult objectAtIndex:i] objectForKey:@"title"];
                NSString *type = [[tableInfoResult objectAtIndex:i] objectForKey:@"dataType"];
                
                if ([[type lowercaseString] isEqualToString:@"integer"]) {
                    [columnData setObject:@"integer" forKey:@"dataType"];
                    [columnData setObject:@([rs intForColumn:columName]) forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"real"]) {
                    [columnData setObject:@"float" forKey:@"dataType"];
                    [columnData setObject:@([rs doubleForColumn:columName]) forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"text"]) {
                    [columnData setObject:@"text" forKey:@"dataType"];
                    [columnData setObject:[rs stringForColumn:columName]?:@"" forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"blob"]) {
                    [columnData setObject:@"blob" forKey:@"dataType"];
                    [columnData setObject:@"blob" forKey:@"value"];
                }else if ([[type lowercaseString] isEqualToString:@"null"]) {
                    [columnData setObject:@"null" forKey:@"dataType"];
                    [columnData setObject:[NSNull null] forKey:@"value"];
                }else {
                    [columnData setObject:@"text" forKey:@"dataType"];
                    [columnData setObject:[rs stringForColumn:columName] forKey:@"value"];
                }
                
                [row addObject:columnData];
            }
            
            [rows addObject:row];
        }
        
        [tableData setObject:rows forKey:@"rows"];
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

@end
