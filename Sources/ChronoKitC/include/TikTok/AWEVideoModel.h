#import <Foundation/Foundation.h>

@class AWEURLModel;

@interface AWEVideoModel : NSObject
@property(readonly, nonatomic) AWEURLModel *playURL;
@property(readonly, nonatomic) AWEURLModel *downloadURL;
@property(readonly, nonatomic) NSNumber *duration;
@end
