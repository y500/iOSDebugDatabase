//
//  NSMutableDictionary+safe.h
//  categories
//
//  Created by wentian on 17/6/1.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (safe)

- (void)safe_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end

// NSDictionary
id dicGetObject(NSDictionary * dic, id aKey, Class aClass);

NSDictionary * dicGetDic(NSDictionary *dic, id aKey);
NSArray * dicGetArray(NSDictionary *dic, id aKey);
NSArray * dicGetArraySafe(NSDictionary *dic, id aKey);

NSString * dicGetString(NSDictionary *dic, id aKey);
NSString * dicGetStringSafe(NSDictionary *dic, id aKey);

int   dicGetInt(NSDictionary *dic, id aKey, int nDefault);
float dicGetFloat(NSDictionary *dic, id aKey, float fDefault);
BOOL  dicGetBool(NSDictionary *dic, id aKey, BOOL bDefault);
