// Real-display probe. Default is read-only; --switch-and-restore temporarily
// requests 1920x1080 through the production function and restores the old mode.
#import <AppKit/AppKit.h>
#include <cstdio>
#include <cstring>
#include <thread>
#include <chrono>
extern "C" bool MacGetMode(CGDirectDisplayID,uint32_t*,uint32_t*);
extern "C" bool MacSetMode(CGDirectDisplayID,uint32_t,uint32_t,bool);
static bool snapshot(CGDirectDisplayID d, const char *label, uint32_t &w, uint32_t &h) {
 auto mode=CGDisplayCopyDisplayMode(d);
 if (!mode) return false;
 bool ok=MacGetMode(d,&w,&h);
 printf("%s reported=%ux%u logical=%zux%zu pixels=%zux%zu\n", label,w,h,
   CGDisplayModeGetWidth(mode),CGDisplayModeGetHeight(mode),
   CGDisplayModeGetPixelWidth(mode),CGDisplayModeGetPixelHeight(mode));
 ok=ok && w==CGDisplayModeGetPixelWidth(mode) && h==CGDisplayModeGetPixelHeight(mode);
 CGDisplayModeRelease(mode);
 return ok;
}
int main(int argc,char **argv) {
 auto display=CGMainDisplayID();
 uint32_t w=0,h=0;
 bool initial=snapshot(display,"before",w,h);
 if(argc==1) return initial?0:1;
 if(argc!=2 || strcmp(argv[1],"--switch-and-restore")) return 2;
 auto original=CGDisplayCopyDisplayMode(display);
 if(!original) return 3;
 bool changed=MacSetMode(display,1920,1080,true);
 std::this_thread::sleep_for(std::chrono::seconds(2));
 bool measured=snapshot(display,"after",w,h);
 auto selected=CGDisplayCopyDisplayMode(display);
 bool layoutPreserved=selected &&
   (CGDisplayModeGetWidth(original)!=1920 || CGDisplayModeGetHeight(original)!=1080 ||
    (CGDisplayModeGetWidth(selected)==1920 && CGDisplayModeGetHeight(selected)==1080));
 if(selected) CGDisplayModeRelease(selected);
 bool passed=initial && changed && measured && layoutPreserved && w==1920 && h==1080;
 printf("requested1920x1080=%s\n",passed?"PASS":"FAIL");
 // Restore the exact original mode, including refresh rate and HiDPI scale,
 // even when the assertion above fails. Do not leave the user's display changed.
 CGDisplayConfigRef config=nullptr;
 auto restored=CGBeginDisplayConfiguration(&config);
 if(restored==kCGErrorSuccess) {
   restored=CGConfigureDisplayWithDisplayMode(config,display,original,nullptr);
   if(restored==kCGErrorSuccess) restored=CGCompleteDisplayConfiguration(config,kCGConfigureForSession);
   else CGCancelDisplayConfiguration(config);
 }
 std::this_thread::sleep_for(std::chrono::seconds(2));
 bool restoreMeasured=snapshot(display,"restored",w,h);
 bool restorePassed=restored==kCGErrorSuccess && restoreMeasured &&
   w==CGDisplayModeGetPixelWidth(original) && h==CGDisplayModeGetPixelHeight(original);
 CGDisplayModeRelease(original);
 printf("restore=%s\n",restorePassed?"PASS":"FAIL");
 return passed && restorePassed?0:1;
}
