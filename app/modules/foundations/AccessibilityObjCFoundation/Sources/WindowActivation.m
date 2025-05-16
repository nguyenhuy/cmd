#import "WindowActivation.h"

@implementation WindowActivation

+ (OSStatus)activateAppAndMakeWindowFront:(NSRunningApplication *)application window:(AXUIElementRef)window
{
    if(!application || application.processIdentifier == -1) {
        return procNotFound; // Previous front most application is nil or does not have a process identifier.
    }
    AXUIElementPerformAction(window, kAXRaiseAction);

    ProcessSerialNumber process;
    OSStatus error = GetProcessForPID(application.processIdentifier, &process); // Deprecated, but replacement (NSRunningApplication:activateWithOptions:] does not work properly on Big Sur.
    if(error) {
        return error; // Process could not be obtained. Evaluate error (e.g. using osstatus.com) to understand why.
    }
    
    return SetFrontProcessWithOptions(&process, kSetFrontProcessFrontWindowOnly); // Deprecated, but replacement (NSRunningApplication:activateWithOptions:] does not work properly on Big Sur.
}

@end
