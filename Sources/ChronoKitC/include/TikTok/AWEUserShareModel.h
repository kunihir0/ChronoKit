#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEUserShareModel: NSObject
@property(nonatomic, copy, readwrite) NSString *shareTitleOther;
@property(nonatomic, assign, readwrite) BOOL isPersist;
@property(nonatomic, copy, readwrite) NSString *shareTitleMyself;
@property(nonatomic, strong, readwrite) AWEURLModel *shareImageURL;
@property(nonatomic, strong, readwrite) NSNumber *timestamp;
@property(nonatomic, copy, readwrite) NSString *statusMsg;
@property(nonatomic, copy, readwrite) NSString *shareDescription;
@property(nonatomic, copy, readwrite) NSString *shareWeiboDescription;
@property(nonatomic, copy, readwrite) NSString *shareTitle;
@property(nonatomic, strong, readwrite) NSNumber *statusCode;
@property(nonatomic, copy, readwrite) NSString *requestID;
@property(nonatomic, strong, readwrite) AWEURLModel *shareQRCodeURL;
@property(nonatomic, copy, readwrite) NSString *logPassback;
@property(nonatomic, copy, readwrite) NSString *shareURL;
@end
