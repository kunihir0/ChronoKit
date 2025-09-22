#import <Foundation/Foundation.h>
#import "AWEShareModel.h"

@interface AWEChallengeModel : NSObject
@property (nonatomic, copy, readwrite) NSString *challengeName;
@property (nonatomic, copy, readwrite) NSString *cid;
@property (nonatomic, copy, readwrite) NSString *desc;
@property (nonatomic, assign, readwrite) BOOL isCommerce;
@property (nonatomic, strong, readwrite) AWEShareModel *shareInfo;
@property (nonatomic, strong, readwrite) NSNumber *userCount;
@end
