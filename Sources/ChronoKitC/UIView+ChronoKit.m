#import "include/UIView+ChronoKit.h"

@implementation UIView (ChronoKit)
- (UIViewController *)parentViewController {
    UIResponder *responder = self;
    while ([responder isKindOfClass:[UIView class]]) {
        responder = [responder nextResponder];
    }
    return (UIViewController *)responder;
}
@end
