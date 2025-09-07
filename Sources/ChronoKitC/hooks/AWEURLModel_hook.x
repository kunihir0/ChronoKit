#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import <os/log.h>

extern os_log_t ck_log;

%hook AWEURLModel

%new - (NSString *)bestURLtoDownloadFormat {
    os_log_error(ck_log, "[VERBOSE] Determining best URL format from list: %{public}@", self.originURLList);
    BOOL hasJPEG = NO;
    BOOL hasHEIC = NO;
    BOOL hasTiktokOriginImage = NO;

    for (NSString *url in self.originURLList) {
        os_log_error(ck_log, "[VERBOSE] Analyzing URL: %@", url);
        if ([url containsString:@".jpeg"]) {
            os_log_error(ck_log, "[VERBOSE] Found .jpeg in URL");
            hasJPEG = YES;
        } else if ([url containsString:@".heic"]) {
            os_log_error(ck_log, "[VERBOSE] Found .heic in URL");
            hasHEIC = YES;
        } else if ([url containsString:@"~tplv-tiktokx-origin.image"]) {
            os_log_error(ck_log, "[VERBOSE] Found ~tplv-tiktokx-origin.image in URL");
            hasTiktokOriginImage = YES;
        }
    }

    if (hasJPEG) {
        os_log_error(ck_log, "[VERBOSE] Final format determined: jpeg (due to .jpeg extension)");
        return @"jpeg";
    } else if (hasHEIC) {
        os_log_error(ck_log, "[VERBOSE] Final format determined: heic (due to .heic extension)");
        return @"heic";
    } else if (hasTiktokOriginImage) {
        os_log_error(ck_log, "[VERBOSE] Final format determined: heic (due to ~tplv-tiktokx-origin.image pattern)");
        return @"heic";
    }

    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"]) {
            os_log_error(ck_log, "[VERBOSE] Final format determined: mp4 (due to video_mp4 pattern)");
            return @"mp4";
        } else if ([url containsString:@".png"]) {
            os_log_error(ck_log, "[VERBOSE] Final format determined: png (due to .png extension)");
            return @"png";
        } else if ([url containsString:@".mp3"]) {
            os_log_error(ck_log, "[VERBOSE] Final format determined: mp3 (due to .mp3 extension)");
            return @"mp3";
        } else if ([url containsString:@".m4a"]) {
            os_log_error(ck_log, "[VERBOSE] Final format determined: m4a (due to .m4a extension)");
            return @"m4a";
        }
    }

    // Fallback to a sensible default
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"/image/"]) {
            os_log_error(ck_log, "[VERBOSE] Final format determined: jpeg (due to /image/ fallback)");
            return @"jpeg";
        }
    }

    os_log_error(ck_log, "[VERBOSE] Could not determine format, defaulting to mp4");
    return @"mp4"; // Default fallback
}

%new - (NSURL *)bestImageURLtoDownload {
    os_log_error(ck_log, "[VERBOSE] Searching for best image URL in list: %{public}@", self.originURLList);
    for (NSString *url in self.originURLList) {
        os_log_error(ck_log, "[VERBOSE] Checking URL for image patterns: %@", url);
        if ([url containsString:@"~tplv-photomode"]) {
            os_log_error(ck_log, "[VERBOSE] Found image URL with pattern '~tplv-photomode': %{public}@", url);
            return [NSURL URLWithString:url];
        }
        if ([url containsString:@"~tplv-tiktokx-origin.image"]) {
            os_log_error(ck_log, "[VERBOSE] Found image URL with pattern '~tplv-tiktokx-origin.image': %{public}@", url);
            return [NSURL URLWithString:url];
        }
    }
    os_log_error(ck_log, "[VERBOSE] No valid image URL was found in the list.");
    return nil; // No more fallback
}

%new - (NSURL *)bestURLtoDownload {
    os_log_error(ck_log, "Searching for best video URL in list: %{public}@", self.originURLList);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"high_quality"]) {
        for (NSString *url in self.originURLList) {
            os_log_error(ck_log, "Checking URL: %{public}@", url);
            if ([url containsString:@"mime_type=video_mp4"] && ![url containsString:@"api16-normal-useast8.tiktokv.us"]) {
                os_log_error(ck_log, "Found high quality video URL: %{public}@", url);
                return [NSURL URLWithString:url];
            }
        }
    } else {
        for (NSString *url in self.originURLList) {
            os_log_error(ck_log, "Checking URL: %{public}@", url);
            if (![url containsString:@"mime_type=video_mp4"] && ![url containsString:@"api16-normal-useast8.tiktokv.us"]) {
                os_log_error(ck_log, "Found low quality video URL: %{public}@", url);
                return [NSURL URLWithString:url];
            }
        }
    }

    if (self.originURLList.count > 0) {
        return [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return nil;
}

%end
