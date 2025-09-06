import UIKit

class SlideOutAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }

        let containerView = transitionContext.containerView
        
        // Add the destination view to the hierarchy and send it to the back
        containerView.insertSubview(toViewController.view, at: 0)

        let finalFrameForVC = transitionContext.finalFrame(for: fromViewController).offsetBy(dx: containerView.frame.width, dy: 0)

        // Animate the view off-screen to the right
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromViewController.view.frame = finalFrameForVC
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
