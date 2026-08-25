#import <Orion/Orion.h>
#import "ChronoKit-TikTok.h"
#import <ChronoKit-Swift.h>
#import <os/log.h>
#import <objc/runtime.h>

extern os_log_t ck_log;
@interface TTKMediaVideoPlayerController : UIViewController
- (void)setIgnoreVideoPlayFinishOnce:(BOOL)ignore;
@end


@interface TTKRichContentDetailViewController : UIViewController
- (AWEAwemeModel *)currentAwemeContext;
- (void)addDownloadButton;
@end


// ============================================================
// MARK: – Save Story
// ============================================================

%hook TTKRichContentDetailViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"story_download_button"]) {
        [self addDownloadButton];
    }
}

%new - (void)addDownloadButton {
    // Only add if not present
    if ([self.view viewWithTag:999]) return;

    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:999];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(ck_storyDownloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    [downloadButton setTintColor:[UIColor whiteColor]];

    // Add a dark shadow to make it visible on light stories
    downloadButton.layer.shadowColor = [UIColor blackColor].CGColor;
    downloadButton.layer.shadowOffset = CGSizeMake(0, 1);
    downloadButton.layer.shadowOpacity = 0.5;
    downloadButton.layer.shadowRadius = 2.0;

    [self.view addSubview:downloadButton];
    [self.view bringSubviewToFront:downloadButton];

    // Position it on the right side, slightly below the top safe area
    [NSLayoutConstraint activateConstraints:@[
        [downloadButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [downloadButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],
        [downloadButton.widthAnchor constraintEqualToConstant:35],
        [downloadButton.heightAnchor constraintEqualToConstant:35],
    ]];
}

%new - (void)ck_storyDownloadButtonHandler:(UIButton *)sender {
    AWEAwemeModel *outerModel = [self currentAwemeContext];
    if (!outerModel) {
        os_log_error(ck_log, "[CK] Story model is nil");
        return;
    }
    
    // For stories (awemeType 40), the actual media is in currentPlayingStory
    AWEAwemeModel *model = outerModel;
    if ([outerModel respondsToSelector:@selector(currentPlayingStory)] && [outerModel currentPlayingStory]) {
        model = [outerModel currentPlayingStory];
    }
    
    [ChronoKitDownloadUIManager.shared showProgressView];

    // Media Metadata
    NSString *itemID = model.itemID;
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:model.createTime.doubleValue];
    NSString *caption = model.desc ?: @"";
    NSInteger mediaTypeInt = (model.photoAlbum != nil) ? 1 : 0;

    NSString *authorID = model.author.userID ?: @"";
    NSString *authorName = model.author.nickname ?: @"";
    NSString *secUserID = model.author.secUserID ?: @"";
    NSString *customID = model.author.customID ?: @"";
    NSString *signature = model.author.signature ?: @"";
    NSString *bioUrl = model.author.bioUrl ?: @"";
    NSNumber *awemeCount = model.author.awemeCount ?: @(0);
    NSNumber *followingCount = model.author.followingCount ?: @(0);
    NSNumber *followerCount = model.author.followerCount ?: @(0);
    NSNumber *favoritingCount = model.author.favoritingCount ?: @(0);
    NSString *accountRegion = model.author.accountRegion ?: @"";
    NSString *country = model.author.country ?: @"";
    NSString *province = model.author.province ?: @"";
    NSString *city = model.author.city ?: @"";
    NSString *language = model.author.language ?: @"";
    BOOL isPrivateAccount = model.author.isPrivateAccount;
    BOOL isProAccount = model.author.isProAccount;
    NSNumber *verificationType = model.author.verificationType ?: @(0);
    NSString *shareURL = model.author.shareInfo.shareURL ?: @"";
    NSString *avatarThumbURI = model.author.avatarThumb.originURLList.firstObject ?: @"";
    NSString *avatarMediumURI = model.author.avatarMedium.originURLList.firstObject ?: @"";
    NSString *avatarLargerURI = model.author.avatarLarger.originURLList.firstObject ?: @"";

    // Statistics Metadata
    NSNumber *playCount = model.statistics.playCount ?: @(0);
    NSNumber *downloadCount = model.statistics.downLoadCount ?: @(0);
    NSNumber *shareCount = model.statistics.shareCount ?: @(0);
    NSNumber *commentCount = model.statistics.commentCount ?: @(0);
    NSNumber *diggCount = model.statistics.diggCount ?: @(0);
    NSNumber *favoriteCount = model.statistics.favoriteCount ?: @(0);

    NSMutableArray *urlLists = [NSMutableArray array];
    if (mediaTypeInt == 0) { // Video
        if (model.video.playURL) {
            NSArray *list = [model.video.playURL chronoKit_URLListToUse];
            if (list) {
                [urlLists addObject:list];
            }
        }
    } else { // Photo Album
        if (model.photoAlbum) {
            for (AWEPhotoAlbumPhoto *photo in model.photoAlbum.photos) {
                if (photo.originPhotoURL) {
                    NSArray *list = [photo.originPhotoURL chronoKit_URLListToUse];
                    if (list) {
                        [urlLists addObject:list];
                    }
                }
            }
        }
    }


    [ChronoKitDownloadManager.shared downloadContentWithItemID:itemID authorName:authorName authorID:authorID creationDate:creationDate caption:caption mediaType:mediaTypeInt urlLists:urlLists secUserID:secUserID customID:customID signature:signature bioUrl:bioUrl awemeCount:awemeCount followingCount:followingCount followerCount:followerCount favoritingCount:favoritingCount accountRegion:accountRegion country:country province:province city:city language:language isPrivateAccount:isPrivateAccount isProAccount:isProAccount verificationType:verificationType shareURL:shareURL avatarThumbURI:avatarThumbURI avatarMediumURI:avatarMediumURI avatarLargerURI:avatarLargerURI playCount:playCount downloadCount:downloadCount shareCount:shareCount commentCount:commentCount diggCount:diggCount favoriteCount:favoriteCount];
}

%end
