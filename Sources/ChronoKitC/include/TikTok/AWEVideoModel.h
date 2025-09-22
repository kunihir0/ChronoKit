#import <Foundation/Foundation.h>
#import "AWEURLModel.h"
#import "AWEVideoMetaModel.h"
#import "AWEVideoBitrateModel.h"
#import "AWEMiscDownloadAddrs.h"

@interface AWEVideoModel: NSObject
@property (nonatomic, strong, readwrite) NSNumber *duration;
@property (nonatomic, strong, readwrite) NSNumber *width;
@property (nonatomic, strong, readwrite) NSNumber *height;
@property (nonatomic, strong, readwrite) AWEURLModel *originCover;
@property (nonatomic, strong, readwrite) AWEURLModel *downloadNoWatermarkURL;
@property (nonatomic, strong, readwrite) AWEVideoMetaModel *meta;
@property (nonatomic, copy, readwrite) NSArray<AWEVideoBitrateModel *> *bitrateModels;
@property (nonatomic, strong, readwrite) AWEURLModel *playURL;
@property (nonatomic, strong, readwrite) AWEURLModel *downloadURL;
@property (nonatomic, assign, readwrite) BOOL isLongVideo;
@property (nonatomic, strong, readwrite) AWEURLModel *animatedCover;
@property (nonatomic, strong, readwrite) AWEURLModel *dynamicCover;
@property (nonatomic, strong, readwrite) AWEMiscDownloadAddrs *miscDownloadAddrs;
@end