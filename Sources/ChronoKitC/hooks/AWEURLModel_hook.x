#import <Orion/Orion.h>
#import <os/log.h>
#import <objc/runtime.h>
#import "ChronoKit-TikTok.h"
#import <ChronoKit-Swift.h>

extern os_log_t ck_log;

// Associated object keys
static void *ChronoKitGoodURLsKey = &ChronoKitGoodURLsKey;

%hook AWEURLModel

- (void)setOriginURLList:(NSArray *)list {
    %orig(list);

    BOOL hasGoodURLs = NO;
    for (NSString *url in list) {
        if ([url containsString:@"~tplv-photomode-image-cover"] || [url containsString:@"~tplv-photomode-image-v1"]) {
            hasGoodURLs = YES;
            break;
        }
    }

    if (hasGoodURLs && ![self ChronoKitGoodURLs]) {
        [self setChronoKitGoodURLs:list];
        os_log_error(ck_log, "[CACHE] Cached good URL list: %@", list);
    }
}

%new
- (void)setChronoKitGoodURLs:(NSArray *)urls {
    objc_setAssociatedObject(self, ChronoKitGoodURLsKey, urls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (NSArray *)ChronoKitGoodURLs {
    return objc_getAssociatedObject(self, ChronoKitGoodURLsKey);
}

%new
- (NSArray *)chronoKit_URLListToUse {
    if (self.ChronoKitGoodURLs) {
        os_log_error(ck_log, "[AWEURLModel+ChronoKit] Using cached URLs: %@", self.ChronoKitGoodURLs);
        return self.ChronoKitGoodURLs;
    }
    os_log_error(ck_log, "[AWEURLModel+ChronoKit] Using origin URLs: %@", self.originURLList);
    return self.originURLList;
}

%end
