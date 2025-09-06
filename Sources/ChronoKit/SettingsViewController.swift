import UIKit

@objc(ChronoKitSettingsViewController)
public class SettingsViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "ChronoKit Settings"
        self.view.backgroundColor = .systemGroupedBackground

        // Add a back button to dismiss the view
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(closeTapped))
        self.navigationItem.leftBarButtonItem = backButton
    }

    @objc func closeTapped() {
        // Dismiss the modally presented view controller
        self.dismiss(animated: true, completion: nil)
    }
}
