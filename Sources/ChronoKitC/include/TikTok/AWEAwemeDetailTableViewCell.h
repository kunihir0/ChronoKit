#import <UIKit/UIKit.h>
#import "AWEAwemeBaseViewController.h"

@interface AWEAwemeDetailTableViewCell: UITableViewCell
@property(nonatomic, strong, readwrite) AWEAwemeBaseViewController *viewController;
- (void)configureWithModel:(id)model;
- (void)addDownloadButton;
- (void)downloadButtonHandler:(UIButton *)sender;
@end
