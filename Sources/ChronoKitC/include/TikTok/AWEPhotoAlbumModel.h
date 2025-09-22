#import <Foundation/Foundation.h>
#import "AWEPhotoAlbumPhoto.h"

@interface AWEPhotoAlbumModel: NSObject
@property (nonatomic, copy, readwrite) NSArray<AWEPhotoAlbumPhoto *> *photos;
@end