#import <Foundation/Foundation.h>
#import "AWEURLModel.h"

@interface AWEShareModel : NSObject
@property (nonatomic, copy, readwrite) NSString *shareURL;
@property (nonatomic, copy, readwrite) NSString *shareDesc;
@property (nonatomic, copy, readwrite) NSString *shareTitle;
@property (nonatomic, copy, readwrite) NSString *shareWeiboDesc;
@property (nonatomic, strong, readwrite) AWEURLModel *shareQRCodeURL;
@property (nonatomic, strong, readwrite) AWEURLModel *shareImageURL;
@property (nonatomic, copy, readwrite) NSString *shareTitleOther;
@property (nonatomic, copy, readwrite) NSString *shareTitleMyself;
@property (nonatomic, assign, readwrite) BOOL isPersist;
@property (nonatomic, strong, readwrite) NSNumber *timestamp;
@property (nonatomic, copy, readwrite) NSString *statusMsg;
@property (nonatomic, strong, readwrite) NSNumber *statusCode;
@property (nonatomic, copy, readwrite) NSString *requestID;
@property (nonatomic, copy, readwrite) NSDictionary *logPassback;
@end
