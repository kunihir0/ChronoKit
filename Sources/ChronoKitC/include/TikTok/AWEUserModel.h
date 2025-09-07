#import <Foundation/Foundation.h>

@interface AWEUserModel: NSObject
@property(nonatomic, copy, readwrite) NSString *bioUrl;
@property(nonatomic, copy, readwrite) NSString *nickname;
@property(nonatomic, copy, readwrite) NSString *signature;
@property(nonatomic, copy, readwrite) NSString *socialName;
@property (nonatomic, strong, readwrite) NSNumber *visibleVideosCount;
@property (nonatomic, copy, readwrite) NSString *userID;
@end
