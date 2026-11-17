#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#include <cmath>
#include <cstring>

namespace {
struct AppMode {
    AXUIElementRef window = nullptr;
    CGRect original = CGRectZero;
    bool resized = false;
    uint32_t windowID = 0;
    NSString *appName = nil;
    ~AppMode() {
        if (!clear()) NSLog(@"LanDesk could not restore the app window after disconnect.");
    }

    static bool frame(AXUIElementRef window, CGRect &rect) {
        CFTypeRef position = nullptr, size = nullptr;
        bool ok = AXUIElementCopyAttributeValue(window, kAXPositionAttribute, &position) == kAXErrorSuccess;
        ok = AXUIElementCopyAttributeValue(window, kAXSizeAttribute, &size) == kAXErrorSuccess && ok;
        if (ok) {
            ok = CFGetTypeID(position) == AXValueGetTypeID() && CFGetTypeID(size) == AXValueGetTypeID()
                && AXValueGetValue((AXValueRef)position, kAXValueTypeCGPoint, &rect.origin)
                && AXValueGetValue((AXValueRef)size, kAXValueTypeCGSize, &rect.size);
        }
        if (position) CFRelease(position);
        if (size) CFRelease(size);
        return ok;
    }

    static bool setFrame(AXUIElementRef window, CGRect rect) {
        AXValueRef size = AXValueCreate(kAXValueTypeCGSize, &rect.size);
        AXValueRef position = AXValueCreate(kAXValueTypeCGPoint, &rect.origin);
        // AppKit animates AX geometry changes. Let each step settle, then resize again
        // at the new position because the old screen edge may have constrained it.
        AXError s = AXUIElementSetAttributeValue(window, kAXSizeAttribute, size);
        [NSThread sleepForTimeInterval:0.3];
        AXError p = AXUIElementSetAttributeValue(window, kAXPositionAttribute, position);
        [NSThread sleepForTimeInterval:0.3];
        s = AXUIElementSetAttributeValue(window, kAXSizeAttribute, size);
        [NSThread sleepForTimeInterval:0.3];
        CFRelease(size);
        CFRelease(position);
        return s == kAXErrorSuccess && p == kAXErrorSuccess;
    }

    bool clear() {
        bool ok = !window || !resized || setFrame(window, original);
        if (window) CFRelease(window);
        window = nullptr;
        resized = false;
        [appName release];
        appName = nil;
        return ok;
    }
};

NSDictionary *error(NSString *text) { return @{ @"error": text }; }

NSDictionary *rectJSON(CGRect r) {
    return @{ @"x": @(r.origin.x), @"y": @(r.origin.y),
              @"width": @(r.size.width), @"height": @(r.size.height) };
}

NSArray *windows() {
    return [(NSArray *)CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID) autorelease];
}

bool candidate(NSDictionary *w) {
    CGRect r;
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:[w[(id)kCGWindowOwnerPID] intValue]];
    return app && app.activationPolicy == NSApplicationActivationPolicyRegular
        && [w[(id)kCGWindowLayer] intValue] == 0
        && CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)w[(id)kCGWindowBounds], &r)
        && r.size.width >= 80 && r.size.height >= 80;
}

AXUIElementRef findWindow(NSDictionary *info) {
    AXUIElementRef app = AXUIElementCreateApplication([info[(id)kCGWindowOwnerPID] intValue]);
    AXUIElementSetMessagingTimeout(app, 1.0);
    CFTypeRef value = nullptr;
    AXUIElementRef found = nullptr;
    CGRect expected;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)info[(id)kCGWindowBounds], &expected);
    if (AXUIElementCopyAttributeValue(app, kAXWindowsAttribute, &value) == kAXErrorSuccess
        && CFGetTypeID(value) == CFArrayGetTypeID()) {
        for (id item in (NSArray *)value) {
            CGRect rect;
            if (AppMode::frame((AXUIElementRef)item, rect)
                && fabs(rect.origin.x - expected.origin.x) < 2 && fabs(rect.origin.y - expected.origin.y) < 2
                && fabs(rect.size.width - expected.size.width) < 2 && fabs(rect.size.height - expected.size.height) < 2) {
                // Ambiguous bounds must not activate a different window.
                if (found) { CFRelease(found); found = nullptr; break; }
                found = (AXUIElementRef)CFRetain((CFTypeRef)item);
            }
        }
    }
    if (value) CFRelease(value);
    CFRelease(app);
    return found;
}

NSDictionary *current(AppMode *state) {
    CGRect rect;
    if (!state->window || !AppMode::frame(state->window, rect)) return error(@"The window is no longer available.");
    return @{ @"window": @{ @"id": @(state->windowID), @"app": state->appName ?: @"",
                             @"frame": rectJSON(rect) } };
}

NSDictionary *handle(AppMode *state, NSDictionary *request) {
    NSString *op = request[@"op"];
    if ([op isEqual:@"desktop"]) {
        return state->clear() ? @{} : error(@"The original window size could not be restored.");
    }
    if (!AXIsProcessTrusted()) return error(@"Allow Accessibility access for LanDesk on the Mac.");
    if ([op isEqual:@"list"]) {
        NSMutableArray *result = [NSMutableArray array];
        for (NSDictionary *w in windows()) {
            if (!candidate(w)) continue;
            CGRect rect;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)w[(id)kCGWindowBounds], &rect);
            [result addObject:@{ @"id": w[(id)kCGWindowNumber],
                @"app": w[(id)kCGWindowOwnerName] ?: @"App",
                @"title": w[(id)kCGWindowName] ?: @"", @"frame": rectJSON(rect) }];
            if (result.count >= 100) break;
        }
        return @{ @"windows": result };
    }
    if ([op isEqual:@"current"]) return current(state);
    if (![op isEqual:@"focus"]) return error(@"Unknown app action.");
    NSDictionary *target = nil;
    for (NSDictionary *w in windows()) {
        if ([w[(id)kCGWindowNumber] unsignedIntValue] == [request[@"window_id"] unsignedIntValue] && candidate(w)) {
            target = w; break;
        }
    }
    if (!target) return error(@"The window is no longer available.");
    AXUIElementRef window = findWindow(target);
    if (!window) return error(@"This app does not expose a controllable window.");
    if (!state->clear()) { CFRelease(window); return error(@"The previous window size could not be restored."); }
    state->window = window;
    state->windowID = [target[(id)kCGWindowNumber] unsignedIntValue];
    state->appName = [target[(id)kCGWindowOwnerName] copy];
    if (!AppMode::frame(window, state->original)) { state->clear(); return error(@"Cannot read the window size."); }
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:[target[(id)kCGWindowOwnerPID] intValue]];
    [app unhide];
    if (![app activateWithOptions:NSApplicationActivateIgnoringOtherApps]
        || AXUIElementPerformAction(window, kAXRaiseAction) != kAXErrorSuccess) {
        state->clear(); return error(@"Cannot activate this window.");
    }
    double aspect = [request[@"aspect"] doubleValue];
    if (aspect > 0) {
        CGDirectDisplayID display = 0; uint32_t count = 0;
        if (CGGetDisplaysWithPoint(CGPointMake(CGRectGetMidX(state->original), CGRectGetMidY(state->original)), 1, &display, &count) != kCGErrorSuccess || count != 1) {
            state->clear(); return error(@"Cannot find the window display.");
        }
        CGRect bounds = CGRectInset(CGDisplayBounds(display), 32, 48);
        for (NSScreen *screen in [NSScreen screens]) {
            if ([screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue] != display) continue;
            NSRect visible = screen.visibleFrame;
            bounds = CGRectInset(CGRectMake(visible.origin.x,
                CGDisplayBounds(CGMainDisplayID()).size.height - NSMaxY(visible),
                visible.size.width, visible.size.height), 16, 16);
            break;
        }
        double requestedHeight = [request[@"height"] doubleValue];
        double height = requestedHeight > 0 ? fmin(bounds.size.height, requestedHeight) : bounds.size.height;
        CGSize size = CGSizeMake(fmin(bounds.size.width, height * aspect), height);
        size.height = fmin(size.height, size.width / aspect);
        CGRect rect = CGRectMake(CGRectGetMidX(bounds) - size.width / 2, CGRectGetMidY(bounds) - size.height / 2, size.width, size.height);
        state->resized = true;
        if (!AppMode::setFrame(window, rect)) {
            state->clear(); return error(@"This window cannot be resized. Try keeping its current size.");
        }
    }
    return current(state);
}
}

extern "C" void *LandeskAppModeCreate() { return new AppMode(); }
extern "C" void LandeskAppModeDestroy(void *state) {
    @autoreleasepool { delete static_cast<AppMode *>(state); }
}
extern "C" char *LandeskAppModeRequest(void *state, const char *request) {
    @autoreleasepool {
        NSError *parseError = nil;
        NSData *data = [[NSString stringWithUTF8String:request] dataUsingEncoding:NSUTF8StringEncoding];
        id input = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        NSDictionary *result = [input isKindOfClass:[NSDictionary class]]
            ? handle(static_cast<AppMode *>(state), input) : error(@"Invalid app request.");
        NSData *output = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
        return strdup([[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] autorelease].UTF8String);
    }
}
