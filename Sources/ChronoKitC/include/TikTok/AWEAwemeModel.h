#import <Foundation/Foundation.h>
#import "AWEVideoModel.h"
#import "AWEMusicModel.h"
#import "AWEPhotoAlbumModel.h"
#import "AWEAwemeStatisticsModel.h"
#import "AWEUserModel.h"
#import "AWELiveRoom.h"
#import "AWELiveStreamURL.h"

@class AWEAwemeCommerceModel;

@interface AWEAwemeModel : NSObject
@property(nonatomic) BOOL isAds;
@property(nonatomic) BOOL hasAd;
@property(nonatomic, copy, readwrite) NSString *promoteIconText;
@property(nonatomic, strong, readwrite) AWEAwemeCommerceModel *commerceModel;
@property(retain, nonatomic) AWEVideoModel *video;
@property(retain, nonatomic) id music;
@property (nonatomic, copy, readwrite) NSString *itemID;
@property(retain, nonatomic) AWEPhotoAlbumModel *photoAlbum;
@property(nonatomic) NSString *music_songName;
@property(nonatomic) NSString *music_artistName;
@property(nonatomic, strong, readwrite) AWEAwemeModel *currentPlayingStory;
@property (nonatomic, copy, readwrite) NSString *region;
@property (nonatomic, strong, readwrite) AWEAwemeStatisticsModel *statistics;
@property (nonatomic, strong, readwrite) NSNumber *createTime;
@property (nonatomic, strong, readwrite) AWEUserModel *author;
@property (nonatomic, assign, readwrite) BOOL isUserRecommendBigCard;
@property (nonatomic, copy, readwrite) NSString *desc;
@property (nonatomic, strong, readwrite) AWELiveRoom *room;
@property (nonatomic, strong, readwrite) AWELiveStreamURL *liveStreamURL;
@property (nonatomic, strong, readwrite) AWEURLModel *downloadAddr;
@property (nonatomic, strong, readwrite) NSNumber *forwardCount;
@property (nonatomic, strong, readwrite) NSArray *imageInfos;
+ (id)liveStreamURLJSONTransformer;
+ (id)relatedLiveJSONTransformer;
+ (id)rawModelFromLiveRoomModel:(id)arg1;
+ (id)aweLiveRoom_subModelPropertyKey;
- (void)live_callInitWithDictyCategoryMethod:(id)arg1;
@end