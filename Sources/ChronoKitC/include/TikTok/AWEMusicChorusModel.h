#import <Foundation/Foundation.h>

@interface AWEMusicChorusModel : NSObject
@property (nonatomic, copy, readwrite) NSString *requestID;
@property (nonatomic, copy, readwrite) NSDictionary *logPassback;
@property (nonatomic, strong, readwrite) NSNumber *statusCode;
@property (nonatomic, strong, readwrite) NSNumber *duration;
@property (nonatomic, strong, readwrite) NSNumber *startTime;
@property (nonatomic, strong, readwrite) NSNumber *timestamp;
@property (nonatomic, copy, readwrite) NSString *statusMsg;
@end
