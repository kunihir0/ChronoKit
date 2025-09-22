#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEMusicModel : NSObject
@property(readonly, nonatomic) AWEURLModel *playURL;
@property (nonatomic, copy, readwrite) NSString *musicName;
@property (nonatomic, copy, readwrite) NSString *authorName;
@property (nonatomic, strong, readwrite) NSNumber *duration;
@property (nonatomic, copy, readwrite) NSString *musicID;
@property (nonatomic, copy, readwrite) NSString *album;
@property (nonatomic, strong, readwrite) AWEURLModel *thumbURL;
@property (nonatomic, strong, readwrite) AWEURLModel *mediumURL;
@property (nonatomic, strong, readwrite) AWEURLModel *largeURL;
@end
