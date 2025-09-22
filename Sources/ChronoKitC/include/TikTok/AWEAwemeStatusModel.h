#import <Foundation/Foundation.h>

@interface AWEAwemeStatusModel : NSObject
@property (nonatomic, assign, readwrite) BOOL allowShare;
@property (nonatomic, assign, readwrite) BOOL allowComment;
@property (nonatomic, assign, readwrite) BOOL allowReact;
@property (nonatomic, assign, readwrite) BOOL isDelete;
@property (nonatomic, assign, readwrite) BOOL isProhibited;
@property (nonatomic, strong, readwrite) NSNumber *privateStatus;
@property (nonatomic, assign, readwrite) BOOL reviewed;
@property (nonatomic, assign, readwrite) BOOL selfSee;
@property (nonatomic, assign, readwrite) BOOL showGoods;
@property (nonatomic, strong, readwrite) NSNumber *status;
@property (nonatomic, assign, readwrite) BOOL withGoods;
@end
