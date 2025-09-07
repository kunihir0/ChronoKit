
#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import "ChronoKit-Swift.h"
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
    os_log_error(ck_log, "Processing model: %{public}@", model);

    NSString *itemID = model.itemID;
    os_log_error(ck_log, "ItemID: %{public}@", itemID);

    AWEUserModel *author = model.author;
    if (!author) {
        os_log_error(ck_log, "author is nil");
        return;
    }
    os_log_error(ck_log, "Author: %{public}@", author.nickname);

    NSNumber *createTime = model.createTime;
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:[createTime doubleValue]];
    NSString *caption = model.desc;

    ChronoKitMediaType mediaType;
    if (model.photoAlbum) {
        mediaType = ChronoKitMediaTypePhotoAlbum;
    } else {
        mediaType = ChronoKitMediaTypeVideo;
    }
    os_log_error(ck_log, "Determined media type: %ld", (long)mediaType);

    ChronoKitMediaMetadata *metadata = [[ChronoKitMediaMetadata alloc] initWithItemID:itemID authorName:author.nickname authorID:author.userID creationDate:creationDate caption:caption mediaType:mediaType primaryLocalFilePath:nil];

    if (mediaType == ChronoKitMediaTypeVideo) {
        os_log_error(ck_log, "Processing as video.");
        AWEVideoModel *video = model.video;
        if (!video) {
            os_log_error(ck_log, "video model is nil");
            return;
        }

        AWEURLModel *playURL = video.playURL;
        if (!playURL) {
            os_log_error(ck_log, "playURL is nil");
            return;
        }
        os_log_error(ck_log, "Video playURL model: %{public}@", playURL);

        NSURL *videoURL = [playURL bestURLtoDownload];
        NSString *format = [playURL bestURLtoDownloadFormat];
        os_log_error(ck_log, "Final video URL: %{public}@, format: %{public}@", videoURL, format);

        if (videoURL) {
            os_log_error(ck_log, "Initiating video download.");
            [ChronoKitDownloadUIManager.shared showProgressView];
            [ChronoKitDownloadManager.shared downloadFileWithUrl:videoURL metadata:metadata format:format];
        }
    } else if (mediaType == ChronoKitMediaTypePhotoAlbum) {
        os_log_error(ck_log, "Processing as photo album.");
        AWEPhotoAlbumModel *photoAlbum = model.photoAlbum;
        if (!photoAlbum) {
            os_log_error(ck_log, "photoAlbum is nil");
            return;
        }

        NSArray<AWEPhotoAlbumPhoto *> *photos = photoAlbum.photos;
        if (!photos || photos.count == 0) {
            os_log_error(ck_log, "photos array is nil or empty");
            return;
        }
        os_log_error(ck_log, "Found %lu photos in album.", (unsigned long)photos.count);

        NSMutableArray<NSURL *> *photoURLs = [NSMutableArray array];
        NSMutableArray<NSString *> *formats = [NSMutableArray array];
        os_log_error(ck_log, "[VERBOSE] Starting photo album processing for %lu photos.", (unsigned long)photos.count);
        for (int i = 0; i < photos.count; i++) {
            AWEPhotoAlbumPhoto *photo = photos[i];
            os_log_error(ck_log, "[VERBOSE] Processing photo %d/%lu with URL model: %{public}@", i+1, (unsigned long)photos.count, photo.originPhotoURL);
            NSURL *photoURL = [photo.originPhotoURL bestImageURLtoDownload];
            if (photoURL) {
                NSString *format = [photo.originPhotoURL bestURLtoDownloadFormat];
                [photoURLs addObject:photoURL];
                [formats addObject:format];
                os_log_error(ck_log, "[VERBOSE] Added photo URL to download list: %@ with format %@", photoURL, format);
            } else {
                os_log_error(ck_log, "[VERBOSE] Could not get a downloadable URL for photo %d/%lu.", i+1, (unsigned long)photos.count);
            }
        }

        if (photoURLs.count > 0) {
            os_log_error(ck_log, "[VERBOSE] Initiating album download for %lu photos with formats: %@", (unsigned long)photoURLs.count, formats);
            [ChronoKitDownloadUIManager.shared showProgressView];
            [ChronoKitDownloadManager.shared downloadFilesWithUrls:photoURLs metadata:metadata formats:formats];
        } else {
            os_log_error(ck_log, "[VERBOSE] No downloadable photos found in album.");
        }
    }
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
    os_log_error(ck_log, "Processing model (AWEAwemeDetailTableViewCell): %{public}@", model);

    NSString *itemID = model.itemID;
    os_log_error(ck_log, "ItemID (AWEAwemeDetailTableViewCell): %{public}@", itemID);

    AWEUserModel *author = model.author;
    if (!author) {
        os_log_error(ck_log, "author is nil (AWEAwemeDetailTableViewCell)");
        return;
    }
    os_log_error(ck_log, "Author (AWEAwemeDetailTableViewCell): %{public}@", author.nickname);

    NSNumber *createTime = model.createTime;
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:[createTime doubleValue]];
    NSString *caption = model.desc;

    ChronoKitMediaType mediaType;
    if (model.photoAlbum) {
        mediaType = ChronoKitMediaTypePhotoAlbum;
    } else {
        mediaType = ChronoKitMediaTypeVideo;
    }
    os_log_error(ck_log, "Determined media type (AWEAwemeDetailTableViewCell): %ld", (long)mediaType);

    ChronoKitMediaMetadata *metadata = [[ChronoKitMediaMetadata alloc] initWithItemID:itemID authorName:author.nickname authorID:author.userID creationDate:creationDate caption:caption mediaType:mediaType primaryLocalFilePath:nil];

    if (mediaType == ChronoKitMediaTypeVideo) {
        os_log_error(ck_log, "Processing as video (AWEAwemeDetailTableViewCell).");
        AWEVideoModel *video = model.video;
        if (!video) {
            os_log_error(ck_log, "video model is nil (AWEAwemeDetailTableViewCell)");
            return;
        }

        AWEURLModel *playURL = video.playURL;
        if (!playURL) {
            os_log_error(ck_log, "playURL is nil (AWEAwemeDetailTableViewCell)");
            return;
        }
        os_log_error(ck_log, "Video playURL model (AWEAwemeDetailTableViewCell): %{public}@", playURL);

        NSURL *videoURL = [playURL bestURLtoDownload];
        NSString *format = [playURL bestURLtoDownloadFormat];
        os_log_error(ck_log, "Final video URL (AWEAwemeDetailTableViewCell): %{public}@, format: %{public}@", videoURL, format);

        if (videoURL) {
            os_log_error(ck_log, "Initiating video download (AWEAwemeDetailTableViewCell).");
            [ChronoKitDownloadUIManager.shared showProgressView];
            [ChronoKitDownloadManager.shared downloadFileWithUrl:videoURL metadata:metadata format:format];
        }
    } else if (mediaType == ChronoKitMediaTypePhotoAlbum) {
        os_log_error(ck_log, "Processing as photo album (AWEAwemeDetailTableViewCell).");
        AWEPhotoAlbumModel *photoAlbum = model.photoAlbum;
        if (!photoAlbum) {
            os_log_error(ck_log, "photoAlbum is nil (AWEAwemeDetailTableViewCell)");
            return;
        }

        NSArray<AWEPhotoAlbumPhoto *> *photos = photoAlbum.photos;
        if (!photos || photos.count == 0) {
            os_log_error(ck_log, "photos array is nil or empty (AWEAwemeDetailTableViewCell)");
            return;
        }
        os_log_error(ck_log, "Found %lu photos in album (AWEAwemeDetailTableViewCell).", (unsigned long)photos.count);

        NSMutableArray<NSURL *> *photoURLs = [NSMutableArray array];
        NSMutableArray<NSString *> *formats = [NSMutableArray array];
        os_log_error(ck_log, "[VERBOSE] Starting photo album processing for %lu photos (AWEAwemeDetailTableViewCell).", (unsigned long)photos.count);
        for (int i = 0; i < photos.count; i++) {
            AWEPhotoAlbumPhoto *photo = photos[i];
            os_log_error(ck_log, "[VERBOSE] Processing photo %d/%lu with URL model (AWEAwemeDetailTableViewCell): %{public}@", i+1, (unsigned long)photos.count, photo.originPhotoURL);
            NSURL *photoURL = [photo.originPhotoURL bestImageURLtoDownload];
            if (photoURL) {
                NSString *format = [photo.originPhotoURL bestURLtoDownloadFormat];
                [photoURLs addObject:photoURL];
                [formats addObject:format];
                os_log_error(ck_log, "[VERBOSE] Added photo URL to download list (AWEAwemeDetailTableViewCell): %@ with format %@", photoURL, format);
            } else {
                os_log_error(ck_log, "[VERBOSE] Could not get a downloadable URL for photo %d/%lu (AWEAwemeDetailTableViewCell).", i+1, (unsigned long)photos.count);
            }
        }

        if (photoURLs.count > 0) {
            os_log_error(ck_log, "[VERBOSE] Initiating album download for %lu photos with formats (AWEAwemeDetailTableViewCell): %@", (unsigned long)photoURLs.count, formats);
            [ChronoKitDownloadUIManager.shared showProgressView];
            [ChronoKitDownloadManager.shared downloadFilesWithUrls:photoURLs metadata:metadata formats:formats];
        } else {
            os_log_error(ck_log, "[VERBOSE] No downloadable photos found in album (AWEAwemeDetailTableViewCell).");
        }
    }
}

%end
