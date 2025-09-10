#import <Foundation/Foundation.h>

@interface AWEURLModel : NSObject
@property(retain, nonatomic) NSArray* originURLList;
- (NSURL *)recommendUrl;
- (NSURL *)bestURLtoDownload;
- (NSString *)bestURLtoDownloadFormat;
- (NSURL *)bestImageURLtoDownload;
- (NSURL *)bestVideoURLtoDownload;
@end
