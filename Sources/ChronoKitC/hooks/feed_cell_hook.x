#import <Orion/Orion.h>
#import "ChronoKit-TikTok.h"
#import <ChronoKit-Swift.h>
#import <os/log.h>

extern os_log_t ck_log;

%hook AWEFeedViewTemplateCell

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"download_button"]) {
        [self addDownloadButton];
    }
}

%new - (void)addDownloadButton {
    os_log_error(ck_log, "Adding download button...");
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];
        [self bringSubviewToFront:downloadButton];
        os_log_error(ck_log, "Download button added.");
        os_log_error(ck_log, "View hierarchy: %@", self);

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
        ]];
    } else {
        os_log_error(ck_log, "Download button already exists.");
    }
}

%new - (void)downloadButtonHandler:(UIButton *)sender {
    os_log_error(ck_log, "Download button tapped.");
    AWEFeedCellViewController *rootVC = (AWEFeedCellViewController *)self.viewController;
    if (!rootVC) {
        os_log_error(ck_log, "rootVC is nil");
        return;
    }

    AWEAwemeModel *model = rootVC.model;
    if (!model) {
        os_log_error(ck_log, "model is nil");
        return;
    }
    
    [ChronoKitDownloadUIManager.shared showProgressView];

    // Media Metadata
    NSString *itemID = model.itemID;
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:model.createTime.doubleValue];
    NSString *caption = model.desc;
    NSInteger mediaTypeInt = (model.photoAlbum != nil) ? 1 : 0;

    // Author Metadata
    NSString *authorID = model.author.userID;
    NSString *authorName = model.author.nickname;
    NSString *secUserID = model.author.secUserID;
    NSString *customID = model.author.customID;
    NSString *signature = model.author.signature;
    NSString *bioUrl = model.author.bioUrl;
    NSNumber *awemeCount = model.author.awemeCount;
    NSNumber *followingCount = model.author.followingCount;
    NSNumber *followerCount = model.author.followerCount;
    NSNumber *favoritingCount = model.author.favoritingCount;
    NSString *accountRegion = model.author.accountRegion;
    NSString *country = model.author.country;
    NSString *province = model.author.province;
    NSString *city = model.author.city;
    NSString *language = model.author.language;
    BOOL isPrivateAccount = model.author.isPrivateAccount;
    BOOL isProAccount = model.author.isProAccount;
    NSNumber *verificationType = model.author.verificationType;
    NSString *shareURL = model.author.shareInfo.shareURL;
    NSString *avatarThumbURI = model.author.avatarThumb.originURLList.firstObject;
    NSString *avatarMediumURI = model.author.avatarMedium.originURLList.firstObject;
    NSString *avatarLargerURI = model.author.avatarLarger.originURLList.firstObject;

    // Statistics Metadata
    NSNumber *playCount = model.statistics.playCount;
    NSNumber *downloadCount = model.statistics.downLoadCount;
    NSNumber *shareCount = model.statistics.shareCount;
    NSNumber *commentCount = model.statistics.commentCount;
    NSNumber *diggCount = model.statistics.diggCount;
    NSNumber *favoriteCount = model.statistics.favoriteCount;

    NSMutableArray *urlLists = [NSMutableArray array];
    if (mediaTypeInt == 0) { // Video
        if (model.video.playURL) {
            NSArray *list = [model.video.playURL chronoKit_URLListToUse];
            if (list) {
                [urlLists addObject:list];
            }
        }
    } else { // Photo Album
        if (model.photoAlbum && model.photoAlbum.photos) {
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

%hook AWEAwemeDetailTableViewCell

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"download_button"]) {
        [self addDownloadButton];
    }
}

%new - (void)addDownloadButton {
    os_log_error(ck_log, "Adding download button (AWEAwemeDetailTableViewCell)...");
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];
        [self bringSubviewToFront:downloadButton];
        os_log_error(ck_log, "Download button added (AWEAwemeDetailTableViewCell).");

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
        ]];
    } else {
        os_log_error(ck_log, "Download button already exists (AWEAwemeDetailTableViewCell).");
    }
}

%new - (void)downloadButtonHandler:(UIButton *)sender {
    os_log_error(ck_log, "Download button tapped (AWEAwemeDetailTableViewCell).");
    AWEAwemeBaseViewController *rootVC = (AWEAwemeBaseViewController *)self.viewController;
    if (!rootVC) {
        os_log_error(ck_log, "rootVC is nil (AWEAwemeDetailTableViewCell)");
        return;
    }

    AWEAwemeModel *model = rootVC.model;
    if (!model) {
        os_log_error(ck_log, "model is nil (AWEAwemeDetailTableViewCell)");
        return;
    }
    
    [ChronoKitDownloadUIManager.shared showProgressView];

    // Media Metadata
    NSString *itemID = model.itemID;
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:model.createTime.doubleValue];
    NSString *caption = model.desc;
    NSInteger mediaTypeInt = (model.photoAlbum != nil) ? 1 : 0;

    // Author Metadata
    NSString *authorID = model.author.userID;
    NSString *authorName = model.author.nickname;
    NSString *secUserID = model.author.secUserID;
    NSString *customID = model.author.customID;
    NSString *signature = model.author.signature;
    NSString *bioUrl = model.author.bioUrl;
    NSNumber *awemeCount = model.author.awemeCount;
    NSNumber *followingCount = model.author.followingCount;
    NSNumber *followerCount = model.author.followerCount;
    NSNumber *favoritingCount = model.author.favoritingCount;
    NSString *accountRegion = model.author.accountRegion;
    NSString *country = model.author.country;
    NSString *province = model.author.province;
    NSString *city = model.author.city;
    NSString *language = model.author.language;
    BOOL isPrivateAccount = model.author.isPrivateAccount;
    BOOL isProAccount = model.author.isProAccount;
    NSNumber *verificationType = model.author.verificationType;
    NSString *shareURL = model.author.shareInfo.shareURL;
    NSString *avatarThumbURI = model.author.avatarThumb.originURLList.firstObject;
    NSString *avatarMediumURI = model.author.avatarMedium.originURLList.firstObject;
    NSString *avatarLargerURI = model.author.avatarLarger.originURLList.firstObject;

    // Statistics Metadata
    NSNumber *playCount = model.statistics.playCount;
    NSNumber *downloadCount = model.statistics.downLoadCount;
    NSNumber *shareCount = model.statistics.shareCount;
    NSNumber *commentCount = model.statistics.commentCount;
    NSNumber *diggCount = model.statistics.diggCount;
    NSNumber *favoriteCount = model.statistics.favoriteCount;

    NSMutableArray *urlLists = [NSMutableArray array];
    if (mediaTypeInt == 0) { // Video
        if (model.video.playURL) {
            NSArray *list = [model.video.playURL chronoKit_URLListToUse];
            if (list) {
                [urlLists addObject:list];
            }
        }
    } else { // Photo Album
        if (model.photoAlbum && model.photoAlbum.photos) {
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
