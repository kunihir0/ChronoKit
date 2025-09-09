import UIKit

@objc(ChronoKitSettingsViewController)
public class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView!
    private var jailbreakStatusIndicator: StatusIndicatorView?
    private var sslStatusIndicator: StatusIndicatorView?

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

    }


    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }


    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // Status section
            return 2
        }
        if section == 1 { // Feed section
            return 2
        }
        if section == 3 { // Developer section
            return 1
        }
        if section == 4 { // About section
            return 3
        }
        return 1
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
            return "Status (App Version: \(version))"
        case 1:
            return "Feed"
        case 2:
            return "Downloads"
        case 3:
            return "Developer"
        case 4:
            return "About"
        default:
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Supported App Version"
                let statusIndicator = StatusIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                if let status = StatusIndicatorView.Status(rawValue: BypassStatusManager.shared.getAppVersionStatus()) {
                    statusIndicator.status = status
                }
                cell.accessoryView = statusIndicator
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "SSL Bypass"
                let statusIndicator = StatusIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                if let status = StatusIndicatorView.Status(rawValue: BypassStatusManager.shared.getSSLBypassStatus()) {
                    statusIndicator.status = status
                }
                self.sslStatusIndicator = statusIndicator
                cell.accessoryView = statusIndicator
            }
        case 1:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Download Button"
                cell.detailTextLabel?.text = "Enable download button for videos"

                let switchView = UISwitch(frame: .zero)
                switchView.setOn(UserDefaults.standard.bool(forKey: "download_button"), animated: true)
                switchView.addTarget(self, action: #selector(downloadButtonToggled(_:)), for: .valueChanged)
                cell.accessoryView = switchView
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Block Ads"
                cell.detailTextLabel?.text = "Block advertisements in the feed"

                let switchView = UISwitch(frame: .zero)
                switchView.setOn(UserDefaults.standard.bool(forKey: "ad_block_enabled"), animated: true)
                switchView.addTarget(self, action: #selector(adBlockToggled(_:)), for: .valueChanged)
                cell.accessoryView = switchView
            }
        case 2:
            cell.textLabel?.text = "High Quality"
            cell.detailTextLabel?.text = "Download videos in high quality"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "high_quality"), animated: true)
            switchView.addTarget(self, action: #selector(highQualityToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        case 3:
            cell.textLabel?.text = "SSL Bypass"
            cell.detailTextLabel?.text = "Enable SSL Pinning Bypass"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "ssl_bypass_enabled"), animated: true)
            switchView.addTarget(self, action: #selector(sslBypassToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        case 4:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Project Repo"
                cell.accessoryType = .disclosureIndicator
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "License"
                cell.detailTextLabel?.text = "Apache License 2.0"
                cell.selectionStyle = .default
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Credits"
                let button = UIButton(type: .system)
                button.setTitle("View Credits", for: .normal)
                
                let creditsMenu = UIMenu(title: "Credits", children: [
                    UIAction(title: "DouX", handler: { _ in self.openURL(string: "https://github.com/kunihir0/DouX") }),
                    UIAction(title: "tiktokusregion", handler: { _ in self.openURL(string: "https://github.com/iGerman00/tiktokusregion.git") }),
                    UIAction(title: "tiktok-god", handler: { _ in self.openURL(string: "https://github.com/haoict/tiktok-god.git") }),
                    UIAction(title: "TikTok-Tweaks", handler: { _ in self.openURL(string: "https://github.com/tuxi/TikTok-Tweaks.git") })
                ])
                
                button.menu = creditsMenu
                button.showsMenuAsPrimaryAction = true
                button.sizeToFit()
                cell.accessoryView = button
            }
        default:
            break
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 4 {
            if indexPath.row == 0 {
                openURL(string: "https://github.com/kunihir0/ChronoKit")
            } else if indexPath.row == 1 {
                openURL(string: "https://www.apache.org/licenses/LICENSE-2.0")
            }
        }
    }

    private func openURL(string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }


    @objc func downloadButtonToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "download_button")
    }

    @objc func adBlockToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "ad_block_enabled")
    }


    @objc func highQualityToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "high_quality")
    }

    @objc func sslBypassToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "ssl_bypass_enabled")
        showRestartAlert()
    }

    private func showRestartAlert() {
        let alert = UIAlertController(title: "Restart Required", message: "Please restart the app for the changes to take effect.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Restart Now", style: .destructive, handler: { _ in
            UserDefaults.standard.synchronize()
            exit(0)
        }))
        present(alert, animated: true)
    }
}
