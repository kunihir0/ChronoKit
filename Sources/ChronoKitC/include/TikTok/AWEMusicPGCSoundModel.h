#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEMusicPGCSoundModel : NSObject
@property (nonatomic, copy, readwrite) NSString *author;
@property (nonatomic, strong, readwrite) AWEURLModel *mediumCoverURL;
@property (nonatomic, copy, readwrite) NSString *clipId;
@property (nonatomic, copy, readwrite) NSString *mixedAuthor;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) id releaseInfo;
@property (nonatomic, copy, readwrite) NSArray *uncertifiedArtists;
@property (nonatomic, copy, readwrite) NSArray *artists;
@property (nonatomic, copy, readwrite) NSString *mixedTitle;
@end
