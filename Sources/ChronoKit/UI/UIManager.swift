import UIKit

@objc(ChronoKitUIManager)
public class UIManager: NSObject {
    
    private static let shared = UIManager()
    private var transitionCoordinator: TransitionCoordinator?

    @objc public static func presentSettings(from viewController: UIViewController) {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        
        // Use our custom transition
        let interactionController = SlideOutInteractionController(navigationController: navController)
        let coordinator = TransitionCoordinator(interactionController: interactionController)
        shared.transitionCoordinator = coordinator // Keep the coordinator alive
        navController.transitioningDelegate = coordinator
        navController.modalPresentationStyle = .fullScreen

        viewController.present(navController, animated: true, completion: nil)
    }
}
