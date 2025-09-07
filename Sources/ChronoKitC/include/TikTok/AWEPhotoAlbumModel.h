#import <Foundation/Foundation.h>

@class AWEPhotoAlbumPhoto;

@interface AWEPhotoAlbumModel: NSObject
@property(readonly, nonatomic) NSArray <AWEPhotoAlbumPhoto *> *photos;
@end
