import UIKit

class TransitionCoordinator: NSObject, UIViewControllerTransitioningDelegate {

    let animator = SlideInAnimator()
    let slideOutAnimator = SlideOutAnimator()
    private var interactionController: SlideOutInteractionController?

    init(interactionController: SlideOutInteractionController?) {
        self.interactionController = interactionController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return slideOutAnimator
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController, interactionController.inProgress else {
            return nil
        }
        return interactionController
    }
}
