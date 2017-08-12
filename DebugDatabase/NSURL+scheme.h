//
//  NSURL+scheme.h
//  OpenPlatform
//
//  Created by wentian on 17/8/10.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (scheme)

/**
 scheme://user:pass@host:1/path/path2/file.html;params?query#fragment
 
 schemeStr: 符合scheme://user:pass@host:1/path/path2/file.html;params?query的
            URL, 不需要的字段可为空
 queryParams: 用来构造query字段，自动做转义处理
 */
+(NSURL *)urlWith:(NSString *)schemeStr queryParams:(NSDictionary *)params;

/**
 scheme://user:pass@host:1/path/path2/file.html;params?query#fragment
 
 把query内容以NSDictionary返回，返回结果自动做反转义处理。
 */
-(NSDictionary *)queryParams;

@end
