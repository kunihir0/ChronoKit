#import <Foundation/Foundation.h>
#import <os/log.h>
#import <Orion/Orion.h>

extern os_log_t ck_log;

%hook TTNetworkManager

- (id)requestForJSONWithURL:(NSString *)URL params:(id)params method:(NSString *)method needCommonParams:(BOOL)needCommonParams callback:(id)callback {
    
    // 1. Anonymous Profile Viewing
    if (URL && [URL containsString:@"view_record/add/v1"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"anon_profile_view_enabled"]) {
            os_log_info(ck_log, "[ChronoKit] Suppressed profile view record: %@", URL);
            return nil;
        }
    }
    
    // 2. Hide My Story Views
    if (URL && [URL containsString:@"story/view/report/v1"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hide_story_views_enabled"]) {
            os_log_info(ck_log, "[ChronoKit] Suppressed story view record: %@", URL);
            return nil; // returning nil bypasses the request
        }
    }

    return %orig;
}

- (id)requestWithURLString:(NSString *)URL params:(id)params method:(NSString *)method needCommonParams:(BOOL)needCommonParams header:(id)header modelClass:(Class)modelClass targetAttributes:(id)attributes requestSerializer:(id)reqSerializer responseSerializer:(id)respSerializer responseBlock:(id)responseBlock completionBlock:(id)completionBlock {
    
    if (URL && [URL containsString:@"view_record/add/v1"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"anon_profile_view_enabled"]) {
            os_log_info(ck_log, "[ChronoKit] Suppressed profile view record: %@", URL);
            return nil;
        }
    }
    
    if (URL && [URL containsString:@"story/view/report/v1"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hide_story_views_enabled"]) {
            os_log_info(ck_log, "[ChronoKit] Suppressed story view record: %@", URL);
            return nil;
        }
    }
    
    return %orig;
}

%end
