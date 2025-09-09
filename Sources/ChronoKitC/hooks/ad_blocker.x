#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import <os/log.h>

extern os_log_t ck_log;

%hook AWEAwemeModel

- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ad_block_enabled"] && [self isAds]) {
        os_log_info(ck_log, "ChronoKit: Blocking ad (initWithDictionary).");
        return nil;
    }
    return %orig;
}

- (id)init {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ad_block_enabled"] && [self isAds]) {
        os_log_info(ck_log, "ChronoKit: Blocking ad (init).");
        return nil;
    }
    return %orig;
}

%end
