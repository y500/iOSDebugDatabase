//
//  NSMutableDictionary+safe.m
//  categories
//
//  Created by wentian on 17/6/1.
//
//

#import "NSMutableDictionary+safe.h"

@implementation NSMutableDictionary (safe)

- (void)safe_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (aKey) {
        if (!anObject) {
            [self removeObjectForKey:aKey];
        }
        else {
            [self setObject:anObject forKey:aKey];
        }
    }
}

@end

// - - -
id yy_dicGetObject(NSDictionary * dic, id aKey, Class aClass) {
    id result = [dic objectForKey:aKey];
    if (result && [result isKindOfClass:aClass]) {
        return result;
    }
    return nil;
}

// - - -
NSDictionary * yy_dicGetDic(NSDictionary *dic, id aKey) {
    return (NSDictionary *)yy_dicGetObject(dic, aKey, [NSDictionary class]);
}

NSArray * yy_dicGetArray(NSDictionary *dic, id aKey) {
    return (NSArray *)yy_dicGetObject(dic, aKey, [NSArray class]);
}

NSArray * yy_dicGetArraySafe(NSDictionary *dic, id aKey) {
    if ([dic objectForKey:aKey] && ![[dic objectForKey:aKey] isKindOfClass:[NSArray class]])
    {
        return [NSArray arrayWithObject:[dic objectForKey:aKey]];
    }
    return yy_dicGetArray(dic, aKey);
}

// - - -
NSString * yy_dicGetString(NSDictionary *dic, id aKey) {
    if (dic == nil || ![dic isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id result = [dic objectForKey:aKey];
    if (result && [result isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@",result];
    } else if (result && [result isKindOfClass:[NSString class]]) {
        return (NSString *)result;
    }
    return nil;
}

NSString * yy_dicGetStringSafe(NSDictionary *dic, id aKey) {
    if (yy_dicGetString(dic, aKey) && yy_dicGetString(dic, aKey).length > 0) {
        return yy_dicGetString(dic, aKey);
    }
    return @"";
}

// - - -
int yy_dicGetInt(NSDictionary *dic, id aKey, int nDefault) {
    if (dic) {
        id result = [dic objectForKey:aKey];
        if (result && [result isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)result intValue];
        }
        else if (result && [result isKindOfClass:[NSString class]]) {
            return [(NSString *)result intValue];
        }
    }
    return nDefault;
}

float yy_dicGetFloat(NSDictionary *dic, id aKey, float fDefault) {
    if (dic) {
        id result = [dic objectForKey:aKey];
        if (result && [result isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)result floatValue];
        }
        else if (result && [result isKindOfClass:[NSString class]]) {
            return [(NSString *)result floatValue];
        }
    }
    return fDefault;
}

BOOL yy_dicGetBool(NSDictionary *dic, id aKey, BOOL bDefault) {
    if (dic) {
        id result = [dic objectForKey:aKey];
        if (result && [result isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)result boolValue];
        }
        else if (result && [result isKindOfClass:[NSString class]]) {
            return [(NSString *)result boolValue];
        }
    }
    return bDefault;
}
