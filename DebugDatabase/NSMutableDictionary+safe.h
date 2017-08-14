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
id yy_dicGetObject(NSDictionary * dic, id aKey, Class aClass);

NSDictionary * yy_dicGetDicYY(NSDictionary *dic, id aKey);
NSArray * yy_dicGetArrayYY(NSDictionary *dic, id aKey);
NSArray * yy_dicGetArraySafe(NSDictionary *dic, id aKey);

NSString * yy_dicGetString(NSDictionary *dic, id aKey);
NSString * yy_dicGetStringSafe(NSDictionary *dic, id aKey);

int   yy_dicGetInt(NSDictionary *dic, id aKey, int nDefault);
float yy_dicGetFloat(NSDictionary *dic, id aKey, float fDefault);
BOOL  yy_dicGetBool(NSDictionary *dic, id aKey, BOOL bDefault);
