#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEMiscDownloadAddrs : NSObject
@property (nonatomic, copy, readwrite) NSString *requestID;
@property (nonatomic, copy, readwrite) NSDictionary *logPassback;
@property (nonatomic, strong, readwrite) AWEURLModel *suffixScene;
@property (nonatomic, strong, readwrite) NSNumber *statusCode;
@property (nonatomic, strong, readwrite) NSNumber *timestamp;
@property (nonatomic, copy, readwrite) NSString *statusMsg;
@property (nonatomic, strong, readwrite) id otherChannel;
@end
