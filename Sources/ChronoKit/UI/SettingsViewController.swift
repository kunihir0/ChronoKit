import UIKit

@objc(ChronoKitSettingsViewController)
public class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView!
    private var statusIndicator: StatusIndicatorView?

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "ChronoKit Settings"
        self.view.backgroundColor = .systemGroupedBackground

        self.tableView = UITableView(frame: self.view.bounds, style: .grouped)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(self.tableView)

        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(closeTapped))
        self.navigationItem.leftBarButtonItem = backButton

        BypassStatusManager.shared.getBypassStatus { [weak self] status in
            if let statusEnum = StatusIndicatorView.Status(rawValue: status) {
                self?.statusIndicator?.status = statusEnum
            }
        }
    }

    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Status"
        case 1:
            return "Feed"
        case 2:
            return "Downloads"
        default:
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Bypass Status"
            let statusIndicator = StatusIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            statusIndicator.status = .pending // Default to pending
            self.statusIndicator = statusIndicator
            cell.accessoryView = statusIndicator
        case 1:
            cell.textLabel?.text = "Download Button"
            cell.detailTextLabel?.text = "Enable download button for videos"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "download_button"), animated: true)
            switchView.addTarget(self, action: #selector(downloadButtonToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        case 2:
            cell.textLabel?.text = "High Quality"
            cell.detailTextLabel?.text = "Download videos in high quality"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "high_quality"), animated: true)
            switchView.addTarget(self, action: #selector(highQualityToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        default:
            break
        }

        return cell
    }

    @objc func downloadButtonToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "download_button")
    }

    @objc func highQualityToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "high_quality")
    }
}
