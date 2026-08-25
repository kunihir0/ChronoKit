#import <Foundation/Foundation.h>

@interface AWEIMMessageAddedReadManager : NSObject
- (void)markConversationAsRead:(id)arg1 completion:(void (^)(BOOL, NSError *))arg2;
@end

@interface AWEIMPrivacySettingManager : NSObject
@property(nonatomic, assign, readwrite) BOOL messageReadStatus;
- (BOOL)messageReadStatus;
@end

%group ReadReceiptsHook

%hook AWEIMMessageAddedReadManager

- (void)markConversationAsRead:(id)arg1 completion:(void (^)(BOOL, NSError *))arg2 {
    BOOL hideMessageViews = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_message_views_enabled"];
    
    if (hideMessageViews) {
        // Suppress the outbound read receipt by not calling %orig.
        // But we MUST invoke the completion block to ensure the local unread badge is cleared.
        if (arg2) {
            arg2(YES, nil);
        }
    } else {
        %orig;
    }
}

%end

%hook AWEIMPrivacySettingManager

- (BOOL)messageReadStatus {
    BOOL alwaysShowReadReceipts = [[NSUserDefaults standardUserDefaults] boolForKey:@"always_show_read_receipts_enabled"];
    
    if (alwaysShowReadReceipts) {
        // Force the client UI to always think the native setting is ON,
        // so it preserves/displays any incoming receipts received from the server.
        return YES;
    }
    
    return %orig;
}

%end

%end

%ctor {
    %init(ReadReceiptsHook);
}
