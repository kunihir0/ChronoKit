
import UIKit

class MediaViewerPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    private var mediaItems: [MediaMetadata]
    private var currentIndex: Int
    private var thumbnailCollectionView: UICollectionView!
    private var hideTimer: Timer?
    private var rightSideBarView: UIView!
    private var abRepeatButton: UIButton!
    private var heartButton: UIButton!
    private var infoButton: UIButton!
    private var shareButton: UIButton!
    private var infoView: VaultItemInfoView!

    init(mediaItems: [MediaMetadata], initialIndex: Int) {
        self.mediaItems = mediaItems
        self.currentIndex = initialIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dispatch to the next runloop to give the collection view time to lay out its cells before we select one.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.thumbnailCollectionView.selectItem(at: IndexPath(item: self.currentIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self

        if let initialViewController = viewController(at: currentIndex) {
            setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
        }

        setupThumbnailCollectionView()
        setupRightSideBar()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)

        setupInfoView()

        resetAutoHideTimer()

        updateControls(for: mediaItems[currentIndex])
        updateFavoriteButtonState()
        infoView.configure(with: mediaItems[currentIndex])
    }

    private func setupInfoView() {
        infoView = VaultItemInfoView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.isHidden = true
        view.addSubview(infoView)

        infoView.onToggleExpansion = { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        }

        NSLayoutConstraint.activate([
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: thumbnailCollectionView.topAnchor)
        ])
    }

    private func updateControls(for mediaItem: MediaMetadata) {
        // The sidebar is always visible, but the A-B repeat button is only for videos.
        let isVideo = mediaItem.mediaType == .video
        abRepeatButton.isHidden = !isVideo
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVC = pageViewController.viewControllers?.first as? MediaViewerViewController, let index = mediaItems.firstIndex(of: currentVC.mediaItem) else {
            return
        }
        currentIndex = index
        updateControls(for: mediaItems[currentIndex])
        updateFavoriteButtonState()
        infoView.configure(with: mediaItems[currentIndex])
        thumbnailCollectionView.selectItem(at: IndexPath(item: currentIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        resetAutoHideTimer()
    }

    func viewController(at index: Int) -> MediaViewerViewController? {
        if index < 0 || index >= mediaItems.count {
            return nil
        }
        let mediaItem = mediaItems[index]
        let vc = MediaViewerViewController(mediaItem: mediaItem)
        vc.onStateChange = { [weak self] state in
            switch state {
            case .none:
                self?.abRepeatButton.setImage(UIImage(systemName: "a.circle"), for: .normal)
            case .settingB:
                self?.abRepeatButton.setImage(UIImage(systemName: "b.circle"), for: .normal)
            case .active:
                self?.abRepeatButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
            }
        }
        vc.onSingleTap = { [weak self] in
            self?.toggleControlsVisibility()
        }
        return vc
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? MediaViewerViewController, let index = mediaItems.firstIndex(of: currentVC.mediaItem) else {
            return nil
        }
        let beforeIndex = index - 1
        return self.viewController(at: beforeIndex)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? MediaViewerViewController, let index = mediaItems.firstIndex(of: currentVC.mediaItem) else {
            return nil
        }
        let afterIndex = index + 1
        return self.viewController(at: afterIndex)
    }

    // MARK: - Thumbnail Collection View

    private func setupThumbnailCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        thumbnailCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailCollectionView.dataSource = self
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        view.addSubview(thumbnailCollectionView)

        NSLayoutConstraint.activate([
            thumbnailCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbnailCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            thumbnailCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCell
        let mediaItem = mediaItems[indexPath.item]
        ThumbnailService.shared.getThumbnail(for: mediaItem) { image in
            cell.imageView.image = image
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedIndex = indexPath.item
        guard let vc = viewController(at: selectedIndex) else { return }
        let direction: UIPageViewController.NavigationDirection = selectedIndex > currentIndex ? .forward : .reverse
        setViewControllers([vc], direction: direction, animated: true, completion: nil)
        currentIndex = selectedIndex
        updateControls(for: mediaItems[currentIndex])
        updateFavoriteButtonState()
        infoView.configure(with: mediaItems[currentIndex])
        resetAutoHideTimer()
    }

    // MARK: - Controls Visibility

    @objc func toggleControlsVisibility() {
        let isHidden = thumbnailCollectionView.isHidden
        thumbnailCollectionView.isHidden = !isHidden
        rightSideBarView.isHidden = !isHidden
        // Also hide the info view if it's open
        if !isHidden {
            infoView.isHidden = true
        }

        if !isHidden {
            resetAutoHideTimer()
        }
    }

    func resetAutoHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.thumbnailCollectionView.isHidden = true
            self?.rightSideBarView.isHidden = true
            self?.infoView.isHidden = true // Hide info view as well
        }
    }

    // MARK: - Right Side Bar

    private func setupRightSideBar() {
        rightSideBarView = UIView()
        rightSideBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightSideBarView)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        abRepeatButton = UIButton(type: .system)
        abRepeatButton.setImage(UIImage(systemName: "a.circle"), for: .normal)
        abRepeatButton.tintColor = .white
        abRepeatButton.addTarget(self, action: #selector(abRepeatButtonTapped), for: .touchUpInside)

        heartButton = UIButton(type: .system)
        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        heartButton.tintColor = .white
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)

        infoButton = UIButton(type: .system)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .white
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)

        shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)

        stackView.addArrangedSubview(abRepeatButton)
        stackView.addArrangedSubview(heartButton)
        stackView.addArrangedSubview(infoButton)
        stackView.addArrangedSubview(shareButton)

        rightSideBarView.addSubview(stackView)

        NSLayoutConstraint.activate([
            rightSideBarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            rightSideBarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightSideBarView.widthAnchor.constraint(equalToConstant: 60),

            stackView.topAnchor.constraint(equalTo: rightSideBarView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: rightSideBarView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: rightSideBarView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: rightSideBarView.trailingAnchor),

            abRepeatButton.widthAnchor.constraint(equalToConstant: 44),
            abRepeatButton.heightAnchor.constraint(equalToConstant: 44),

            heartButton.widthAnchor.constraint(equalToConstant: 44),
            heartButton.heightAnchor.constraint(equalToConstant: 44),

            infoButton.widthAnchor.constraint(equalToConstant: 44),
            infoButton.heightAnchor.constraint(equalToConstant: 44),

            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func abRepeatButtonTapped() {
        if let currentVC = viewControllers?.first as? MediaViewerViewController {
            currentVC.handleABRepeatAction()
        }
    }

    @objc private func heartButtonTapped() {
        let item = mediaItems[currentIndex]
        item.isFavorite.toggle()
        updateFavoriteButtonState()
        infoView.configure(with: item) // Refresh the info view
        HapticFeedbackManager.shared.playImpact(style: .light)

        do {
            VaultJSONService.shared.updateFavoriteStatus(for: item.itemID, isFavorite: item.isFavorite)
        } catch {
            // Handle error
            print("Error updating favorite status: \(error)")
        }
    }

    private func updateFavoriteButtonState() {
        heartButton.isSelected = mediaItems[currentIndex].isFavorite
    }

    @objc private func infoButtonTapped() {
        infoView.isHidden.toggle()
    }

    @objc private func shareButtonTapped() {
        let item = mediaItems[currentIndex]
        let provider = EncryptedMediaItemProvider(item: item)
        let activityVC = UIActivityViewController(activityItems: [provider], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
        }
        
        present(activityVC, animated: true, completion: nil)
    }

    // MARK: - Pan to Dismiss

    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        resetAutoHideTimer()
        let translation = sender.translation(in: view)

        switch sender.state {
        case .changed:
            if translation.y > 0 {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity
                }
            }
        default:
            break
        }
    }
}
class EncryptedMediaItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let mediaItem: MediaMetadata
    
    init(item: MediaMetadata) {
        self.mediaItem = item
        super.init(placeholderItem: Data())
    }
    
    override var item: Any {
        guard let filePath = mediaItem.primaryLocalFilePath else { return Data() }
        let url = VaultJSONService.shared.getURL(for: filePath)
        do {
            let encryptedData = try Data(contentsOf: url)
            return try EncryptionManager.shared.decrypt(data: encryptedData)
        } catch {
            return Data()
        }
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return mediaItem.mediaType == .video ? "public.mpeg-4" : "public.jpeg"
    }
}
