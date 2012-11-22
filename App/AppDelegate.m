//
//  AppDelegate.m
//  minizip
//
//  Created by Daniel Eggert on 11/22/12.
//  Copyright (c) 2012 Daniel Eggert. All rights reserved.
//

#import "AppDelegate.h"

#import "BOMiniZipArchiver.h"



@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self createArchive];
    
    return YES;
}

- (void)createArchive;
{
    NSURL *directory = [NSBundle mainBundle].bundleURL;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directory includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:0 errorHandler:^BOOL(NSURL *url, NSError *error) {
        return YES;
    }];
    
    NSError *error = nil;
    NSURL *outputFileURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    outputFileURL = [outputFileURL URLByAppendingPathComponent:@"output.zip"];
    
    BOMiniZipArchiver *archiver = [[BOMiniZipArchiver alloc] initWithFileURL:outputFileURL append:NO error:&error];
    NSAssert(archiver != nil, @"%@", error);
    
    for (NSURL *fileURL in enumerator) {
        NSNumber *isFile = nil;
        if (![fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:NULL] ||
            ![isFile boolValue])
        {
            continue;
        }

        NSAssert([archiver appendFileAtURL:fileURL error:&error], @"%@", error);
    }
    
    NSAssert([archiver finishEncoding:&error], @"%@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
