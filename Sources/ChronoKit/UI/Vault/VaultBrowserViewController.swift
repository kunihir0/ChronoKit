import UIKit

@objc(ChronoKitVaultBrowserViewController)
public class VaultBrowserViewController: UIViewController, UICollectionViewDelegate {

    private var creatorID: String?
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, MediaMetadata>!
    private var media: [MediaMetadata] = []

    public init(creatorID: String?) {
        self.creatorID = creatorID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Media Browser"
        self.view.backgroundColor = .systemGroupedBackground

        setupCollectionView()
        setupDataSource()
        loadMedia()
    }

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(VaultItemCell.self, forCellWithReuseIdentifier: "VaultItemCell")
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalWidth(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, MediaMetadata>(collectionView: collectionView) {
            (collectionView, indexPath, mediaItem) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VaultItemCell", for: indexPath) as! VaultItemCell
            
            ThumbnailService.shared.getThumbnail(for: mediaItem) { image in
                cell.imageView.image = image
            }
            
            return cell
        }
    }

    private func loadMedia() {
        do {
            self.media = try VaultDatabaseService.shared.loadMedia(for: self.creatorID)
            applySnapshot()
        } catch {
            print("Error loading media: \(error)")
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, MediaMetadata>()
        snapshot.appendSections([0])
        snapshot.appendItems(media)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pageVC = MediaViewerPageViewController(mediaItems: media, initialIndex: indexPath.item)
        pageVC.modalPresentationStyle = .fullScreen
        present(pageVC, animated: true, completion: nil)
    }
}
