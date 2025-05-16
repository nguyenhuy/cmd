#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WindowActivation : NSObject

/**
 * Makes the specified application's window the frontmost window.
 * @param application The NSRunningApplication to bring to front
 * @param window The AXUIElementRef representing the window to activate
 * @return OSStatus indicating success (0) or an error code
 */
+ (OSStatus)activateAppAndMakeWindowFront:(NSRunningApplication *)application window:(AXUIElementRef)window;

@end

NS_ASSUME_NONNULL_END
