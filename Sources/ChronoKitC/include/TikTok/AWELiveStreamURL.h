#import <Foundation/Foundation.h>

@interface AWELiveStreamURL: NSObject
@property (nonatomic, copy, readwrite) NSString *rtmpURL;
@property (nonatomic, copy, readwrite) NSDictionary *liveRawData;
@end
