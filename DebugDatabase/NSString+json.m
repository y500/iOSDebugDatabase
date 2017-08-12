//
//  NSString+json.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/12.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "NSString+json.h"

@implementation NSString (json)

-(id)JSONObject{
    NSError *errorJson;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&errorJson];
    if (errorJson != nil) {
        NSLog(@"fail to get dictioanry from JSON: %@, error: %@", self, errorJson);
    }
    return jsonDict;
}

@end

@implementation NSString (URLEncode)

- (NSString *)urlEncode {
    NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)URLDecode {
    NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}


@end

