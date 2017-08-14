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
id yy_arrGetObject(NSArray *arr, NSUInteger index, Class aClass);
NSDictionary * yy_arrGetDic(NSArray *arr, NSUInteger index);
NSString * yy_arrGetString(NSArray *arr, NSUInteger index);
NSArray * yy_arrGetArray(NSArray *arr, NSUInteger index);
