#import <Foundation/Foundation.h>
#import "TTKMusicAppleMusicAuthTokenInfo.h"

@interface TTKMusic3rdPartyDSPAuthTokenInfo : NSObject
@property (nonatomic, strong, readwrite) id deezerToken;
@property (nonatomic, strong, readwrite) id anghamiToken;
@property (nonatomic, strong, readwrite) TTKMusicAppleMusicAuthTokenInfo *appleMusicToken;
@property (nonatomic, strong, readwrite) id youtubeMusicToken;
@property (nonatomic, strong, readwrite) id spotifyToken;
@property (nonatomic, strong, readwrite) id soundcloudToken;
@property (nonatomic, strong, readwrite) id amazonMusicToken;
@property (nonatomic, strong, readwrite) id melonToken;
@end
