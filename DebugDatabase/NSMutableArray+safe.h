//
//  NSMutableArray+safe.h
//  categories
//
//  Created by wentian on 17/6/1.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (safe)

- (void)safe_addObject:(id)anObject;

@end

// NSArray
id arrGetObject(NSArray *arr, NSUInteger index, Class aClass);
NSDictionary * arrGetDic(NSArray *arr, NSUInteger index);
NSString * arrGetString(NSArray *arr, NSUInteger index);
NSArray * arrGetArray(NSArray *arr, NSUInteger index);
