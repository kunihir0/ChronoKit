#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEPhotoAlbumPhoto: NSObject
@property (nonatomic, strong, readwrite) AWEURLModel *originPhotoURL;
@property (nonatomic, strong, readwrite) AWEURLModel *userWatermarkedPhotoURL;
@property (nonatomic, strong, readwrite) AWEURLModel *ownerWatermarkedPhotoURL;
@property (nonatomic, strong, readwrite) AWEURLModel *thumbnailPhotoURL;
@property (nonatomic, strong, readwrite) AWEURLModel *translatedOriginPhotoURL;
@property (nonatomic, strong, readwrite) NSNumber *timestamp;
@property (nonatomic, copy, readwrite) NSString *statusMsg;
@property (nonatomic, copy, readwrite) NSString *alternateText;
@property (nonatomic, copy, readwrite) NSArray *photoRankedURLModels;
@end