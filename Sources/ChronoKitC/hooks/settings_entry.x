#import <Orion/Orion.h>
#import <ChronoKit-TikTok.h>
#import "ChronoKit-Swift.h"
#import <os/log.h>
#import <objc/runtime.h>

extern os_log_t ck_log;

static UIViewController* topMostController(void);

#import "../include/UIView+ChronoKit.h"

// ============================================================
// MARK: – Hamburger-menu entry (TTKProfileMenuViewController)
// ============================================================
// The profile hamburger menu is built by TTKProfileMenuViewController
// using a component architecture (TTKCComponentManager).  The menu's
// scroll content is a UICollectionView.  We find the "Settings and
// privacy" cell and place our entry right above it.
// ============================================================

static void *kChronoKitBannerKey = &kChronoKitBannerKey;

static UIView* ck_findCollectionViewIn(UIView *view) {
    if ([view isKindOfClass:[UICollectionView class]]) return view;
    for (UIView *sub in view.subviews) {
        UIView *found = ck_findCollectionViewIn(sub);
        if (found) return found;
    }
    return nil;
}

// Recursively search for a UILabel whose text contains the target string
static UILabel* ck_findLabelWithText(UIView *view, NSString *target) {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.text && [label.text localizedCaseInsensitiveContainsString:target]) {
            return label;
        }
    }
    for (UIView *sub in view.subviews) {
        UILabel *found = ck_findLabelWithText(sub, target);
        if (found) return found;
    }
    return nil;
}

%hook TTKProfileMenuViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Guard: only inject once per presentation
    if (objc_getAssociatedObject(self, kChronoKitBannerKey)) return;
    objc_setAssociatedObject(self, kChronoKitBannerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIView *containerView = ((UIViewController *)self).view;
    UICollectionView *cv = (UICollectionView *)ck_findCollectionViewIn(containerView);
    UIScrollView *scrollView = cv ?: nil;

    // Fallback: try any UIScrollView subview
    if (!scrollView) {
        for (UIView *sub in containerView.subviews) {
            if ([sub isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView *)sub;
                break;
            }
        }
    }

    if (!scrollView) {
        os_log_error(ck_log, "[CK] Hamburger menu: could not find scroll view");
        return;
    }

    // Use a short delay to ensure all cells have been laid out
    __weak UIScrollView *weakScroll = scrollView;
    __weak UIViewController *weakSelf = (UIViewController *)self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIScrollView *sv = weakScroll;
        UIViewController *strongSelf = weakSelf;
        if (!sv || !strongSelf) return;

        // Find the "Settings and privacy" cell
        UILabel *settingsLabel = ck_findLabelWithText(sv, @"Settings");
        if (!settingsLabel) {
            // Fallback: also try "Settings & privacy" or localized variants
            settingsLabel = ck_findLabelWithText(sv, @"privacy");
        }

        CGFloat rowHeight = 56.0;
        CGFloat menuWidth = sv.bounds.size.width;
        CGFloat bannerY = 0;

        if (settingsLabel) {
            // Walk up to the cell (the top-level subview of the scroll view)
            UIView *cell = settingsLabel;
            while (cell.superview && cell.superview != sv) {
                cell = cell.superview;
            }
            // Position banner just above the Settings cell
            bannerY = cell.frame.origin.y;

            // Push the Settings cell (and anything below) down
            for (UIView *sub in sv.subviews) {
                if (sub.tag == 0xCB01) continue; // skip our banner
                if (sub.frame.origin.y >= bannerY) {
                    CGRect f = sub.frame;
                    f.origin.y += rowHeight;
                    sub.frame = f;
                }
            }

            // Expand content size
            CGSize cs = sv.contentSize;
            cs.height += rowHeight;
            sv.contentSize = cs;
        } else {
            // Fallback: put at the bottom of existing content
            bannerY = sv.contentSize.height;
            CGSize cs = sv.contentSize;
            cs.height += rowHeight;
            sv.contentSize = cs;
            os_log_info(ck_log, "[CK] Could not find Settings cell; placing banner at bottom");
        }

        // Build the ChronoKit banner row
        UIView *banner = [[UIView alloc] initWithFrame:CGRectMake(0, bannerY, menuWidth, rowHeight)];
        banner.backgroundColor = [UIColor clearColor];
        banner.tag = 0xCB01;

        // Icon
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"gearshape.fill"]];
        icon.tintColor = [UIColor labelColor];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.frame = CGRectMake(16, (rowHeight - 24) / 2.0, 24, 24);
        [banner addSubview:icon];

        // Title label
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, 0, menuWidth - 72, rowHeight)];
        titleLabel.text = @"ChronoKit Settings";
        titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        titleLabel.textColor = [UIColor labelColor];
        [banner addSubview:titleLabel];

        // Separator at bottom
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(52, rowHeight - 0.5, menuWidth - 52, 0.5)];
        sep.backgroundColor = [UIColor separatorColor];
        [banner addSubview:sep];

        // Tap gesture
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:strongSelf action:@selector(ck_openSettings:)];
        [banner addGestureRecognizer:tap];

        [sv addSubview:banner];
        os_log_info(ck_log, "[CK] Hamburger menu: injected ChronoKit banner at y=%.0f", bannerY);
    });
}

%new
- (void)ck_openSettings:(UITapGestureRecognizer *)tap {
    UIViewController *vc = (UIViewController *)self;

    // Dismiss the hamburger menu sheet first
    [vc dismissViewControllerAnimated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIViewController *top = topMostController();
            if (top.navigationController) {
                ChronoKitSettingsViewController *swiftVC = [[ChronoKitSettingsViewController alloc] init];
                [top.navigationController pushViewController:swiftVC animated:YES];
            } else {
                [ChronoKitUIManager presentSettingsFrom:top];
            }
        });
    }];
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
