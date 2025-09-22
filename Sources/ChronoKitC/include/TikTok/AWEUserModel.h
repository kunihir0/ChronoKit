#import <Foundation/Foundation.h>
#import "AWEURLModel.h"
#import "AWEUserShareModel.h"

@interface AWEUserModel: NSObject
@property(nonatomic, copy, readwrite) NSString *bioUrl;
@property(nonatomic, copy, readwrite) NSString *nickname;
@property(nonatomic, copy, readwrite) NSString *signature;
@property(nonatomic, copy, readwrite) NSString *socialName;
@property (nonatomic, strong, readwrite) NSNumber *visibleVideosCount;
@property (nonatomic, copy, readwrite) NSString *userID;
@property(nonatomic, strong, readwrite) NSNumber *favoritingCount;
@property(nonatomic, strong, readwrite) NSNumber *followerCount;
@property(nonatomic, strong, readwrite) NSNumber *followingCount;
@property(nonatomic, assign, readwrite) BOOL isPrivateAccount;
@property(nonatomic, assign, readwrite) BOOL isProAccount;
@property(nonatomic, copy, readwrite) NSString *language;
@property(nonatomic, copy, readwrite) NSString *province;
@property(nonatomic, copy, readwrite) NSString *secUserID;
@property(nonatomic, strong, readwrite) AWEUserShareModel *shareInfo;
@property(nonatomic, strong, readwrite) NSNumber *verificationType;
@property(nonatomic, strong, readwrite) AWEURLModel *avatarThumb;
@property(nonatomic, strong, readwrite) AWEURLModel *avatarMedium;
@property(nonatomic, strong, readwrite) AWEURLModel *avatarLarger;
@property(nonatomic, copy, readwrite) NSString *customID;
@property(nonatomic, strong, readwrite) NSNumber *awemeCount;
@property(nonatomic, copy, readwrite) NSString *accountRegion;
@property(nonatomic, copy, readwrite) NSString *country;
@property(nonatomic, copy, readwrite) NSString *city;
@property(nonatomic, assign, readwrite) BOOL isBusinessAccount;
@property(nonatomic, assign, readwrite) BOOL isEmailVerified;
@property(nonatomic, assign, readwrite) BOOL isPhoneBinded;
@property(nonatomic, strong, readwrite) NSNumber *registerTime;
@property(nonatomic, strong, readwrite) NSNumber *uniqueIdModifyTime;
@property(nonatomic, strong, readwrite) NSNumber *createTime;
@end
