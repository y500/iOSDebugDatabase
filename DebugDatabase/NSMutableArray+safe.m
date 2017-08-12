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
id arrGetObject(NSArray *arr, NSUInteger index, Class aClass) {
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
NSDictionary * arrGetDic(NSArray *arr, NSUInteger index) {
    NSDictionary *result = nil;
    if ( index<arr.count ) {
        result = [arr objectAtIndex:index];
        if ( result && [result isKindOfClass:[NSDictionary class]] ) {
            return result;
        }
    }
    return nil;
}

NSString * arrGetString(NSArray *arr, NSUInteger index) {
    id object = arrGetObject(arr, index, [NSObject class]);
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    if ([object isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@",object];
    }
    return nil;
}

NSArray * arrGetArray(NSArray *arr, NSUInteger index) {
    return arrGetObject(arr, index, [NSArray class]);
}
