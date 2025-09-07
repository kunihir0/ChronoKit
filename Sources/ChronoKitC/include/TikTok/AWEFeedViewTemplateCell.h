#import <UIKit/UIKit.h>
#import "AWEFeedCellViewController.h"

@interface AWEFeedViewTemplateCell : UITableViewCell
@property (nonatomic, weak) AWEFeedCellViewController *viewController;
- (void)addDownloadButton;
@end
