#import <Foundation/Foundation.h>
#import "TTKMusic3rdPartyDSPAuthTokenInfo.h"

@interface TTKMusicTT2DSPSongInfo : NSObject
@property (nonatomic, copy, readwrite) NSString *songID;
@property (nonatomic, strong, readwrite) TTKMusic3rdPartyDSPAuthTokenInfo *authToken;
@property (nonatomic, strong, readwrite) NSNumber *platform;
@property (nonatomic, assign, readwrite) BOOL alwaysShowInFYPOn;
@property (nonatomic, assign, readwrite) BOOL saved;
@property (nonatomic, assign, readwrite) BOOL selected;
@property (nonatomic, strong, readwrite) NSNumber *buttonType;
@property (nonatomic, strong, readwrite) NSNumber *showMDPTT2DSPStatus;
@end
