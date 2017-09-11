//
//  DatabaseUtil.h
//  YYDebugDatabase
//
//  Created by wentian on 17/8/11.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMutableDictionary+safe.h"
#import "NSMutableArray+safe.h"

@interface DatabaseUtil : NSObject

+ (instancetype)shared;

- (BOOL)openDatabase:(NSString*)dbPath;
- (BOOL)closeDatabase;
- (NSArray*)allTables;
- (NSArray*)tableInfo:(NSString*)tableName;
- (NSDictionary*)rowsInTable:(NSString*)tableName;
- (BOOL)updateRecordInDatabase:(NSString*)database tableName:(NSString*)tableName data:(NSDictionary*)data condition:(NSDictionary*)condition;
- (BOOL)deleteRecordInDatabase:(NSString *)database tableName:(NSString *)tableName condition:(NSDictionary *)condition limit:(NSString *)limit;
- (NSDictionary*)executeQueryInDatabase:(NSString*)database tableName:(NSString*)tableName operator:(NSString*)operator query:(NSString*)query;
- (NSDictionary*)userDefaultData;
- (NSDictionary*)getAppInfoData;
@end
