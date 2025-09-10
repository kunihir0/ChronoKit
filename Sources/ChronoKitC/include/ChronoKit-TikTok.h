#import "TikTok/AWESettingItemModel.h"
#import "TikTok/TTKSettingsBaseCellPlugin.h"
#import "TikTok/AWESettingsNormalSectionViewModel.h"
#import "TikTok/AWEFeedViewTemplateCell.h"
#import "TikTok/AWEFeedCellViewController.h"
#import "TikTok/AWEAwemeModel.h"
#import "TikTok/AWEVideoModel.h"
#import "TikTok/AWEMusicModel.h"
#import "TikTok/AWEPhotoAlbumModel.h"
#import "TikTok/AWEAwemeStatisticsModel.h"
#import "TikTok/AWEUserModel.h"
#import "TikTok/AWEURLModel.h"
#import "TikTok/AWEPhotoAlbumPhoto.h"
#import "TikTok/AWEAwemeDetailTableViewCell.h"

@interface AWEURLModel (ChronoKit)

- (void)setChronoKitGoodURLs:(NSArray *)urls;
- (NSArray *)ChronoKitGoodURLs;
- (NSArray *)chronoKit_URLListToUse;

@end