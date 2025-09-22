import UIKit

@objc(ChronoKitVaultBrowserViewController)
public class VaultBrowserViewController: UIViewController, UICollectionViewDelegate {

    private var creatorID: String?
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, MediaMetadata>!
    private var media: [MediaMetadata] = []
    private var isFavoritesFilterActive = false
    private var filterButton: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!

    private enum SortMode {
        case downloadDate
        case creationDate
    }
    private var currentSortMode: SortMode = .downloadDate

    public init(creatorID: String?) {
        self.creatorID = creatorID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:)")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Media Browser"
        self.view.backgroundColor = .systemGroupedBackground

        setupNavButtons()
        setupCollectionView()
        setupDataSource()
        loadMedia()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMedia() // Reload data to reflect potential favorite changes
    }

    private func setupNavButtons() {
        filterButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(filterButtonTapped))

        let sortByDownload = UIAction(title: "Sort by Download Date") { [weak self] _ in
            self?.updateSortMode(to: .downloadDate)
        }
        let sortByCreation = UIAction(title: "Sort by Creation Date") { [weak self] _ in
            self?.updateSortMode(to: .creationDate)
        }
        let sortMenu = UIMenu(title: "Sort By", children: [sortByDownload, sortByCreation])
        sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), menu: sortMenu)

        navigationItem.rightBarButtonItems = [filterButton, sortButton]
    }

    @objc private func filterButtonTapped() {
        isFavoritesFilterActive.toggle()
        let imageName = isFavoritesFilterActive ? "heart.fill" : "heart"
        filterButton.image = UIImage(systemName: imageName)
        applySnapshot()
    }

    private func updateSortMode(to mode: SortMode) {
        currentSortMode = mode
        applySnapshot()
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
            
            cell.configure(with: mediaItem)

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

        var itemsToDisplay = isFavoritesFilterActive ? media.filter { $0.isFavorite } : media

        switch currentSortMode {
        case .downloadDate:
            itemsToDisplay.sort { $0.downloadDate > $1.downloadDate }
        case .creationDate:
            itemsToDisplay.sort { $0.creationDate > $1.creationDate }
        }

        snapshot.appendItems(itemsToDisplay)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var itemsToDisplay = isFavoritesFilterActive ? media.filter { $0.isFavorite } : media

        switch currentSortMode {
        case .downloadDate:
            itemsToDisplay.sort { $0.downloadDate > $1.downloadDate }
        case .creationDate:
            itemsToDisplay.sort { $0.creationDate > $1.creationDate }
        }

        let pageVC = MediaViewerPageViewController(mediaItems: itemsToDisplay, initialIndex: indexPath.item)
        pageVC.modalPresentationStyle = .fullScreen
        present(pageVC, animated: true, completion: nil)
    }
}
