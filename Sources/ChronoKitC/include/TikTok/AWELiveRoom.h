#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWELiveRoom: NSObject
@property (nonatomic, copy, readwrite) NSString *roomID;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSNumber *user_count;
@property (nonatomic, strong, readwrite) AWEURLModel *roomCover;
@end
