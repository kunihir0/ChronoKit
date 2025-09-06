
import UIKit

class SlideOutInteractionController: UIPercentDrivenInteractiveTransition {
    private var navigationController: UINavigationController!
    private var shouldCompleteTransition = false
    var inProgress = false

    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = .left
        self.navigationController.view.addGestureRecognizer(gesture)
    }

    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let translate = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)
        let progress = translate.x / (gestureRecognizer.view?.bounds.size.width ?? 1)

        switch gestureRecognizer.state {
        case .began:
            inProgress = true
            navigationController.dismiss(animated: true, completion: nil)
        case .changed:
            shouldCompleteTransition = progress > 0.3
            update(progress)
        case .cancelled:
            inProgress = false
            cancel()
        case .ended:
            inProgress = false
            if shouldCompleteTransition {
                finish()
            } else {
                cancel()
            }
        default:
            break
        }
    }
}
