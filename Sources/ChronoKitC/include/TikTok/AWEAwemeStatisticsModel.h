#import <Foundation/Foundation.h>

@interface AWEAwemeStatisticsModel: NSObject
@property (nonatomic, strong, readwrite) NSNumber *playCount;
@property (nonatomic, strong, readwrite) NSNumber *downLoadCount;
@property (nonatomic, strong, readwrite) NSNumber *shareCount;
@property (nonatomic, strong, readwrite) NSNumber *commentCount;
@property (nonatomic, strong, readwrite) NSNumber *diggCount;
@property (nonatomic, strong, readwrite) NSNumber *favoriteCount;
@property (nonatomic, strong, readwrite) NSNumber *repostCount;
@property (nonatomic, strong, readwrite) NSNumber *upvoteCount;
@property (nonatomic, strong, readwrite) NSNumber *loseCommentCount;
@property (nonatomic, strong, readwrite) NSNumber *loseCount;
@property (nonatomic, copy, readwrite) NSString *itemID;
@property (nonatomic, copy, readwrite) NSString *requestID;
@property (nonatomic, copy, readwrite) NSDictionary *logPassback;
@property (nonatomic, copy, readwrite) NSString *statusMsg;
@property (nonatomic, strong, readwrite) NSNumber *statusCode;
@property (nonatomic, strong, readwrite) NSNumber *timestamp;
@end