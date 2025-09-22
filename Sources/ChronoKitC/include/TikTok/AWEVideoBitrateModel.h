#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEVideoBitrateModel: NSObject
@property (nonatomic, strong, readwrite) NSNumber *bitrate;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSNumber *imageWidth;
@property (nonatomic, strong, readwrite) NSNumber *imageHeight;
@property (nonatomic, strong, readwrite) AWEURLModel *playAddr;
@end
