#import <Foundation/Foundation.h>
#import "AWEURLModel.h"
#import "AWEMusicChorusModel.h"

@interface AWEMusicUGCSoundModel : NSObject
@property (nonatomic, copy, readwrite) NSString *author;
@property (nonatomic, strong, readwrite) AWEURLModel *mediumCoverURL;
@property (nonatomic, copy, readwrite) NSArray *performers;
@property (nonatomic, copy, readwrite) NSString *h5URL;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) AWEMusicChorusModel *chorusInfo;
@property (nonatomic, copy, readwrite) NSString *matchedSongID;
@property (nonatomic, strong, readwrite) NSNumber *fullDuration;
@end
