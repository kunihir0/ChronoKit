import UIKit

@objc(ChronoKitSettingsViewController)
public class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView!

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
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Feed"
        } else {
            return "Downloads"
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            cell.textLabel?.text = "Download Button"
            cell.detailTextLabel?.text = "Enable download button for videos"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "download_button"), animated: true)
            switchView.addTarget(self, action: #selector(downloadButtonToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        } else {
            cell.textLabel?.text = "High Quality"
            cell.detailTextLabel?.text = "Download videos in high quality"

            let switchView = UISwitch(frame: .zero)
            switchView.setOn(UserDefaults.standard.bool(forKey: "high_quality"), animated: true)
            switchView.addTarget(self, action: #selector(highQualityToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
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
