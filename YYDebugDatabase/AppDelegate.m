//
//  AppDelegate.m
//  YYDebugDatabase
//
//  Created by wentian on 17/8/9.
//  Copyright © 2017年 wentian. All rights reserved.
//

#import "AppDelegate.h"
#import "DebugDatabaseManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSFileManager*fileManager =[NSFileManager defaultManager];
    NSError*error;
    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString*documentsDirectory =[paths objectAtIndex:0];
    
    NSString*txtPath =[documentsDirectory stringByAppendingPathComponent:@"document.db"];
    
    if([fileManager fileExistsAtPath:txtPath]== NO){
        NSString*resourcePath =[[NSBundle mainBundle] pathForResource:@"Car" ofType:@"db"];
        [fileManager copyItemAtPath:resourcePath toPath:txtPath error:&error];
        NSLog(@"%@", error);
    }
    
    NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
    NSString *databaseDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/database"];
    NSString *documentDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *cacheDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Cache"];
    [[DebugDatabaseManager shared] startServerOnPort:9002 directories:@[resourceDirectory, databaseDirectory, documentDirectory, cacheDirectory]];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
