#import <Foundation/Foundation.h>

@class AWEVideoModel, AWEMusicModel, AWEPhotoAlbumModel, AWEAwemeStatisticsModel, AWEUserModel;

@interface AWEAwemeModel : NSObject
@property(nonatomic) BOOL isAds;
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
+ (id)liveStreamURLJSONTransformer;
+ (id)relatedLiveJSONTransformer;
+ (id)rawModelFromLiveRoomModel:(id)arg1;
+ (id)aweLiveRoom_subModelPropertyKey;
- (void)live_callInitWithDictyCategoryMethod:(id)arg1;
@end
