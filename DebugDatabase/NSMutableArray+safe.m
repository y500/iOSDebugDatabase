//
//  NSMutableArray+safe.m
//  categories
//
//  Created by wentian on 17/6/1.
//
//

#import "NSMutableArray+safe.h"

@implementation NSMutableArray (safe)

- (void)safe_addObject:(id)anObject {
    if (anObject) {
        [self addObject:anObject];
    }
}

@end

// - - - -
id yy_arrGetObject(NSArray *arr, NSUInteger index, Class aClass) {
    NSDictionary *result = nil;
    if (index < arr.count) {
        result = [arr objectAtIndex:index];
        if (result && [result isKindOfClass:aClass]) {
            return result;
        }
    }
    return nil;
}

// - - -
NSDictionary * yy_arrGetDic(NSArray *arr, NSUInteger index) {
    NSDictionary *result = nil;
    if ( index<arr.count ) {
        result = [arr objectAtIndex:index];
        if ( result && [result isKindOfClass:[NSDictionary class]] ) {
            return result;
        }
    }
    return nil;
}

NSString * yy_arrGetString(NSArray *arr, NSUInteger index) {
    id object = yy_arrGetObject(arr, index, [NSObject class]);
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    if ([object isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@",object];
    }
    return nil;
}

NSArray * yy_arrGetArray(NSArray *arr, NSUInteger index) {
    return yy_arrGetObject(arr, index, [NSArray class]);
}
