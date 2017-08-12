//
//  NSString+json.h
//  YYDebugDatabase
//
//  Created by wentian on 17/8/12.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (json)

-(id)JSONObject;

@end

@interface NSString (URLEncode)
- (NSString *)urlEncode;
- (NSString *)URLDecode;
@end
