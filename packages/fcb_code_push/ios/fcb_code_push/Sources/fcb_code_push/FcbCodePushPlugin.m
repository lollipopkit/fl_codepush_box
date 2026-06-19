// Copyright (c) 2026, the FCB project authors.

#import "FcbCodePushPlugin.h"
#import <UIKit/UIKit.h>

@implementation FcbCodePushPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"dev.fcb.code_push/paths"
                                  binaryMessenger:[registrar messenger]];
  FcbCodePushPlugin* instance = [[FcbCodePushPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPaths" isEqualToString:call.method]) {
    [self getPaths:result];
  } else if ([@"restart" isEqualToString:call.method]) {
    [self restartApp:result];
  } else if ([@"log" isEqualToString:call.method]) {
    NSLog(@"%@", [call.arguments isKindOfClass:[NSString class]] ? call.arguments : @"");
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)getPaths:(FlutterResult)result {
  NSArray<NSString*>* cachesPaths =
      NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString* cachesDir = cachesPaths.firstObject ?: NSTemporaryDirectory();
  NSString* fcbCacheDir = [cachesDir stringByAppendingPathComponent:@"fcb"];

  NSError* error = nil;
  [[NSFileManager defaultManager] createDirectoryAtPath:fcbCacheDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];

  result(@{@"cacheDir" : fcbCacheDir});
}

- (void)restartApp:(FlutterResult)result {
  result(nil);
  // iOS does not support programmatic app restart; request user to relaunch.
  // Send the app to background as the closest equivalent.
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] performSelector:@selector(suspend)];
  });
}

@end
