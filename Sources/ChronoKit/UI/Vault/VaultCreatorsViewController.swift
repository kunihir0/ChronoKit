import UIKit

@objc(ChronoKitVaultCreatorsViewController)
public class VaultCreatorsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView!
    private var creators: [(authorID: String, authorName: String)] = []

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Media Vault"
        self.view.backgroundColor = .systemGroupedBackground

        self.tableView = UITableView(frame: self.view.bounds, style: .grouped)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(VaultCreatorCell.self, forCellReuseIdentifier: "CreatorCell")
        self.view.addSubview(self.tableView)

        fetchCreators()
    }

    private func fetchCreators() {
        do {
            self.creators = try VaultDatabaseService.shared.fetchCreators()
            self.tableView.reloadData()
        } catch {
            print("Error fetching creators: \(error)")
        }
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creators.count + 1 // +1 for "All Items"
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CreatorCell", for: indexPath) as! VaultCreatorCell
        if indexPath.row == 0 {
            cell.nameLabel.text = "All Items"
            do {
                let count = try VaultDatabaseService.shared.getTotalMediaCount()
                cell.countLabel.text = "\(count)"
            } catch {
                cell.countLabel.text = "0"
            }
        } else {
            let creator = creators[indexPath.row - 1]
            cell.nameLabel.text = creator.authorName
            do {
                let count = try VaultDatabaseService.shared.getMediaCount(for: creator.authorID)
                cell.countLabel.text = "\(count)"
            } catch {
                cell.countLabel.text = "0"
            }
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var creatorID: String?
        if indexPath.row == 0 {
            creatorID = nil // for "All Items"
        } else {
            creatorID = creators[indexPath.row - 1].authorID
        }

        let browserVC = VaultBrowserViewController(creatorID: creatorID)
        self.navigationController?.pushViewController(browserVC, animated: true)
    }
}
