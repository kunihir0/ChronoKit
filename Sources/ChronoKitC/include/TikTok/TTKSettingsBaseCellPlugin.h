#import <Foundation/Foundation.h>
#import "AWESettingItemModel.h"

@interface TTKSettingsBaseCellPlugin: NSObject
@property(nonatomic, weak, readwrite) id context;
@property(nonatomic, strong, readwrite) AWESettingItemModel *itemModel;
@property(nonatomic, weak, readwrite) UITableViewCell *cell;
- (instancetype)initWithPluginContext:(id)context;
@end
