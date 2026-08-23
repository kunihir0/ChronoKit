#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import "ChronoKit-Swift.h"
#import <os/log.h>
#import <objc/runtime.h>

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

static UIViewController* topMostController();

#import "../include/UIView+ChronoKit.h"

%hook TTKSettingsBaseCellPlugin
- (void)didSelectItemAtIndex:(NSInteger)index {
    if ([self.itemModel.identifier isEqualToString:@"chronokit_settings"]) {
        UIViewController *presentingVC = self.cell.parentViewController;
        
        if (presentingVC && presentingVC.navigationController) {
            ChronoKitSettingsViewController *swiftVC = [[ChronoKitSettingsViewController alloc] init];
            [presentingVC.navigationController pushViewController:swiftVC animated:YES];
        } else {
            os_log_error(ck_log, "Could not find a navigation controller to push from. Using modal fallback.");
            UIViewController *topController = topMostController();
            [ChronoKitUIManager presentSettingsFrom:topController];
        }
    } else {
        %orig;
    }
}
%end

static UIViewController* topMostController() {
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


// --- RGB TEXT ANIMATION ---
// Hooking UILabel directly is much more reliable than guessing TikTok's view hierarchy
static void *kDisplayLinkKey = &kDisplayLinkKey;
static void *kHueKey = &kHueKey;
static void *kIsUpdatingKey = &kIsUpdatingKey;

@interface UILabel (RGBWave)
- (void)startRGBAnimation;
- (void)stopRGBAnimation;
- (void)rgbTick:(CADisplayLink *)link;
@end

%hook UILabel

- (void)setText:(NSString *)text {
    %orig;
    if ([text isEqualToString:@"ChronoKit Settings"]) {
        [self startRGBAnimation];
    } else {
        [self stopRGBAnimation];
    }
}

- (void)setAttributedText:(NSAttributedString *)text {
    NSNumber *isUpdating = objc_getAssociatedObject(self, kIsUpdatingKey);
    if ([isUpdating boolValue]) {
        %orig;
        return;
    }
    
    %orig;
    if ([text.string isEqualToString:@"ChronoKit Settings"]) {
        [self startRGBAnimation];
    } else {
        [self stopRGBAnimation];
    }
}

%new
- (void)startRGBAnimation {
    CADisplayLink *existingLink = objc_getAssociatedObject(self, kDisplayLinkKey);
    if (!existingLink) {
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(rgbTick:)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        objc_setAssociatedObject(self, kDisplayLinkKey, link, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, kHueKey, @(0.0), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (void)stopRGBAnimation {
    CADisplayLink *link = objc_getAssociatedObject(self, kDisplayLinkKey);
    if (link) {
        [link invalidate];
        objc_setAssociatedObject(self, kDisplayLinkKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (void)rgbTick:(CADisplayLink *)link {
    NSNumber *hueNum = objc_getAssociatedObject(self, kHueKey);
    CGFloat hue = [hueNum floatValue];
    hue += 0.02; // Speed of the wave
    if (hue > 1.0) hue -= 1.0;
    objc_setAssociatedObject(self, kHueKey, @(hue), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Prevent recursive loop when setting attributedText
    objc_setAssociatedObject(self, kIsUpdatingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *textStr = self.text ?: @"ChronoKit Settings";
    NSMutableAttributedString *attrStr;
    if (self.attributedText) {
        attrStr = [self.attributedText mutableCopy];
    } else {
        attrStr = [[NSMutableAttributedString alloc] initWithString:textStr];
    }
    
    // Offset hue for each character to create a horizontal wave
    for (NSUInteger i = 0; i < attrStr.length; i++) {
        CGFloat charHue = hue + (CGFloat)i * 0.05;
        charHue = charHue - (int)charHue; // Wrap around 1.0
        
        UIColor *color = [UIColor colorWithHue:charHue saturation:1.0 brightness:1.0 alpha:1.0];
        [attrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(i, 1)];
    }
    
    self.attributedText = attrStr;
    
    objc_setAssociatedObject(self, kIsUpdatingKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end
