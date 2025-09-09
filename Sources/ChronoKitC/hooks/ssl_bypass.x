#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>

%hook TTHttpTask

- (BOOL)skipSSLCertificateError {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ssl_bypass_enabled"]) {
        return YES;
    }
    return %orig;
}

%end