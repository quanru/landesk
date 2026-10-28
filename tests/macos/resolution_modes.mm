// Compile against the production Objective-C++ implementation with a fake display.
// No real display mode or user session is changed by this regression test.
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#include <cassert>
#include <cstdio>
struct Mode { size_t w, h, pw, ph; };
static Mode low{1920,1080,1920,1080}, retina{1920,1080,3840,2160}, native{3840,2160,3840,2160};
static Mode *current = &retina, *configured = nullptr;
static bool reject = false, cancelled = false;
static CGDisplayModeRef testCopyMode(CGDirectDisplayID) { return (CGDisplayModeRef)current; }
static void testReleaseMode(CGDisplayModeRef) {}
static size_t testWidth(CGDisplayModeRef m) { return ((Mode*)m)->w; }
static size_t testHeight(CGDisplayModeRef m) { return ((Mode*)m)->h; }
static size_t testPixelWidth(CGDisplayModeRef m) { return ((Mode*)m)->pw; }
static size_t testPixelHeight(CGDisplayModeRef m) { return ((Mode*)m)->ph; }
static double testRefresh(CGDisplayModeRef) { return 60; }
static CFStringRef testEncoding(CGDisplayModeRef) { return CFStringCreateCopy(nullptr, CFSTR("IO32BitDirectPixels")); }
static CFArrayRef testModes(CGDirectDisplayID, CFDictionaryRef) {
 const void *modes[] = {&native, &retina, &low};
 return CFArrayCreate(nullptr, modes, 3, nullptr);
}
static CGError testBegin(CGDisplayConfigRef *c) { *c=(CGDisplayConfigRef)&current; return kCGErrorSuccess; }
static CGError testConfigure(CGDisplayConfigRef,CGDirectDisplayID,CGDisplayModeRef m,CFDictionaryRef) {
 configured=(Mode*)m; return reject ? kCGErrorFailure : kCGErrorSuccess;
}
static CGError testComplete(CGDisplayConfigRef,CGConfigureOption) { current=configured; return kCGErrorSuccess; }
static CGError testCancel(CGDisplayConfigRef) { cancelled=true; return kCGErrorSuccess; }
#define CGDisplayCopyDisplayMode testCopyMode
#define CGDisplayModeRelease testReleaseMode
#define CGDisplayModeGetWidth testWidth
#define CGDisplayModeGetHeight testHeight
#define CGDisplayModeGetPixelWidth testPixelWidth
#define CGDisplayModeGetPixelHeight testPixelHeight
#define CGDisplayModeGetRefreshRate testRefresh
#define CGDisplayModeCopyPixelEncoding testEncoding
#define CGDisplayCopyAllDisplayModes testModes
#define CGBeginDisplayConfiguration testBegin
#define CGConfigureDisplayWithDisplayMode testConfigure
#define CGCompleteDisplayConfiguration testComplete
#define CGCancelDisplayConfiguration testCancel
#include "../../src/platform/macos.mm"
int main() {
 uint32_t w=0,h=0,n=0,ws[3],hs[3]; bool hidpi[3];
 assert(MacGetMode(1,&w,&h));
 assert(w==3840 && h==2160); // A request for 1080p must not short-circuit.
 assert(MacGetModes(1,ws,hs,hidpi,3,&n) && n==3);
 assert(ws[0]==3840 && ws[1]==3840 && ws[2]==1920);
 assert(hs[0]==2160 && hs[1]==2160 && hs[2]==1080);
 assert(MacSetMode(1,1920,1080,true) && current==&low);
 assert(MacGetMode(1,&w,&h) && w==1920 && h==1080);
 assert(MacSetMode(1,3840,2160,true) && current==&retina);
 assert(!MacSetMode(1,1234,567,true) && current==&retina);
 reject=true;
 assert(!MacSetMode(1,1920,1080,true) && current==&retina && cancelled);
 puts("PASS: pixel enumeration/current mode, 1080p selection, Retina restoration, unsupported mode, transaction cancellation");
}
