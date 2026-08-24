#import <Foundation/Foundation.h>
#import <os/log.h>
#import <Orion/Orion.h>
#import "../include/ChronoKit-TikTok.h"

extern os_log_t ck_log;

%hook TTKProfileViewsVisitor

- (void)reportProfileView {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"anon_profile_view_enabled"]) {
        os_log_info(ck_log, "[ChronoKit] Suppressed profile view report.");
        return;
    }

    %orig;
}

%end
