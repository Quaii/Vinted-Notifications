#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <UserNotifications/UserNotifications.h>

@implementation AppDelegate

// CRITICAL: Explicitly disable Fabric (New Architecture)
// This overrides RCTAppDelegate's default behavior
// We need to override BOTH concurrentRootEnabled and bridgelessEnabled
// to fully disable the New Architecture in React Native 0.81.4
- (BOOL)concurrentRootEnabled
{
  return NO;
}

- (BOOL)bridgelessEnabled
{
  return NO;
}

// Explicitly disable Fabric
- (BOOL)fabricEnabled
{
  return NO;
}

// Override to ensure legacy bridge mode is used
- (NSDictionary *)prepareInitialProps
{
  NSMutableDictionary *initProps = [NSMutableDictionary new];
  #if DEBUG
    // Add any debug props here if needed
  #endif
  return initProps;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"VintedNotifications";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  // Background fetch is now handled by react-native-background-fetch
  // using BGTaskScheduler (iOS 13+) instead of deprecated setMinimumBackgroundFetchInterval

  // Request notification permissions
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (granted) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
      });
    }
  }];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
