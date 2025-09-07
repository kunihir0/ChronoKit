#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import "ChronoKit-Swift.h"
#import <os/log.h>

extern os_log_t ck_log;

%hook AWESettingsNormalSectionViewModel
- (void)viewDidLoad {
    %orig;
    if ([self.sectionIdentifier isEqualToString:@"account"]) {
        TTKSettingsBaseCellPlugin *chronoKitCellPlugin = [[%c(TTKSettingsBaseCellPlugin) alloc] initWithPluginContext:self.context];
        
        AWESettingItemModel *chronoKitItemModel = [[%c(AWESettingItemModel) alloc] initWithIdentifier:@"chronokit_settings"];
        [chronoKitItemModel setTitle:@"ChronoKit Settings"];
        [chronoKitItemModel setIconImage:[UIImage systemImageNamed:@"gear"]];
        [chronoKitItemModel setType:1001];

        [chronoKitCellPlugin setItemModel:chronoKitItemModel];
        [self insertModel:chronoKitCellPlugin atIndex:0 animated:YES];
    }
}
%end

// Forward declare the helper function
static UIViewController* topMostController();

#import "../include/UIView+ChronoKit.h"

%hook TTKSettingsBaseCellPlugin
- (void)didSelectItemAtIndex:(NSInteger)index {
    if ([self.itemModel.identifier isEqualToString:@"chronokit_settings"]) {
        // Get the view controller from the cell that this plugin manages
        UIViewController *presentingVC = self.cell.parentViewController;
        
        if (presentingVC && presentingVC.navigationController) {
            ChronoKitSettingsViewController *swiftVC = [[ChronoKitSettingsViewController alloc] init];
            [presentingVC.navigationController pushViewController:swiftVC animated:YES];
        } else {
            // Fallback just in case
            os_log_error(ck_log, "Could not find a navigation controller to push from. Using modal fallback.");
        UIViewController *topController = topMostController();
        [ChronoKitUIManager presentSettingsFrom:topController];
        }
    } else {
        %orig;
    }
}

%end

// Helper function to get the top-most view controller.
static UIViewController* topMostController() {
    // Modern, scene-aware way to get the key window.
    UIWindow *keyWindow = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            keyWindow = scene.windows.firstObject;
            break;
        }
    }

    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}
