
import UIKit
import AVKit

class EncryptedVideoResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    let filePath: String
    private var decryptedData: Data?

    init(filePath: String) {
        self.filePath = filePath
        super.init()
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if decryptedData == nil {
            do {
                let url = VaultJSONService.shared.getURL(for: filePath)
                let encryptedData = try Data(contentsOf: url)
                decryptedData = try EncryptionManager.shared.decrypt(data: encryptedData)
            } catch {
                print("Resource loader failed: \(error)"); loadingRequest.finishLoading(with: error)
                return false
            }
        }

        guard let data = decryptedData else {
            loadingRequest.finishLoading(with: NSError(domain: "EncryptedVideoResourceLoader", code: -1, userInfo: nil))
            return false
        }

        if let infoRequest = loadingRequest.contentInformationRequest {
            infoRequest.isByteRangeAccessSupported = true
            infoRequest.contentType = "public.mpeg-4"
            infoRequest.contentLength = Int64(data.count)
        }

        if let dataRequest = loadingRequest.dataRequest {
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)

            if currentOffset < data.count {
                let bytesRemaining = data.count - currentOffset
                let bytesRequested = requestedOffset + requestedLength - currentOffset
                let bytesToRespond = min(bytesRemaining, bytesRequested)

                if bytesToRespond > 0 {
                    let subdata = data.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
                    dataRequest.respond(with: subdata)
                }
            }
            
            if Int(dataRequest.currentOffset) >= requestedOffset + requestedLength || Int(dataRequest.currentOffset) >= data.count {
                loadingRequest.finishLoading()
            }
        } else {
            loadingRequest.finishLoading()
        }
        return true
    }
}

class MediaViewerViewController: UIViewController, UIGestureRecognizerDelegate {

    let mediaItem: MediaMetadata
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var imageView: UIImageView?
    private var resourceLoaderDelegate: EncryptedVideoResourceLoader?

    // Properties for scrubbing
    private var isScrubbing = false
    private var initialScrubTime: CMTime?
    private var initialTouchLocation: CGPoint?

    // Properties for A-B Repeat
    public enum ABRepeatState { case none, settingB, active }
    private var abRepeatState: ABRepeatState = .none {
        didSet { onStateChange?(abRepeatState) }
    }
    private var pointA: CMTime?
    private var pointB: CMTime?
    private var abRepeatObserver: Any?
    public var onStateChange: ((ABRepeatState) -> Void)?
    public var onSingleTap: (() -> Void)?

    private var singleTapGesture: UITapGestureRecognizer!
    private var longPressGesture: UILongPressGestureRecognizer!

    private var panGesture: UIPanGestureRecognizer!

    init(mediaItem: MediaMetadata) {
        self.mediaItem = mediaItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mediaItem.mediaType == .video {
            player?.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if mediaItem.mediaType == .video {
            player?.pause()
        }
    }

    private func setupView() {
        // Create gestures that are needed by media-specific setups first.
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.require(toFail: doubleTapGesture)
        view.addGestureRecognizer(singleTapGesture)

        // Now setup the media view itself
        if mediaItem.mediaType == .video {
            setupVideoPlayer()
        } else {
            setupImageView()
        }

        // Setup remaining gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)

        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.panGesture.delegate = self
        self.panGesture.isEnabled = false
        view.addGestureRecognizer(self.panGesture)
    }

    private func setupImageView() {
        guard let filePath = mediaItem.primaryLocalFilePath else { return }
        let url = VaultJSONService.shared.getURL(for: filePath)
        do {
            let encryptedData = try Data(contentsOf: url)
            let data = try EncryptionManager.shared.decrypt(data: encryptedData)
            guard let image = UIImage(data: data) else { return }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(imageView)
            self.imageView = imageView
        } catch {
            print("Error decrypting image: \(error)")
        }
    }

    private func setupVideoPlayer() {
        guard let filePath = mediaItem.primaryLocalFilePath else { return }
        
        let customURL = URL(string: "encrypted-video://\(UUID().uuidString)")!
        let asset = AVURLAsset(url: customURL)
        
        resourceLoaderDelegate = EncryptedVideoResourceLoader(filePath: filePath)
        let loaderQueue = DispatchQueue(label: "com.chronokit.resourceloader"); asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: loaderQueue)
        
        let playerItem = AVPlayerItem(asset: asset)

        player = AVQueuePlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect

        if let player = player {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        }

        if let playerLayer = playerLayer {
            view.layer.addSublayer(playerLayer)
        }

        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleScrubbing(_:)))
        longPressGesture.minimumPressDuration = 0.2
        view.addGestureRecognizer(longPressGesture)

        // The single tap gesture is now global, but we need to make sure it doesn't fire when we long-press on a video.
        singleTapGesture.require(toFail: longPressGesture)
    }



    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
        imageView?.frame = view.bounds

        if let playerLayer = playerLayer {
            playerLayer.videoGravity = .resizeAspect
        }
    }

    @objc private func handleSingleTap() {
        onSingleTap?()
        if mediaItem.mediaType == .video {
            toggleVideoPlayback()
        }
    }

    @objc private func toggleVideoPlayback() {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }

    @objc private func handleScrubbing(_ gesture: UILongPressGestureRecognizer) {
        guard let player = player, let _ = player.currentItem?.duration else { return }

        let location = gesture.location(in: view)

        switch gesture.state {
        case .began:
            isScrubbing = true
            player.pause()
            initialScrubTime = player.currentTime()
            initialTouchLocation = location

        case .changed:
            guard isScrubbing, let initialTouchLocation = initialTouchLocation, let initialScrubTime = initialScrubTime else { return }

            let horizontalMovement = location.x - initialTouchLocation.x
            let scrubSensitivity: Float64 = 0.1 // Adjust this value to change scrubbing speed
            let timeOffset = Float64(horizontalMovement) * scrubSensitivity

            let newTime = CMTimeAdd(initialScrubTime, CMTime(seconds: timeOffset, preferredTimescale: 600))
            player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)

        case .ended, .cancelled:
            isScrubbing = false
            player.play()
            initialScrubTime = nil
            initialTouchLocation = nil

        default:
            break
        }
    }

    // MARK: - A-B Repeat Methods

    public func handleABRepeatAction() {
        guard let player = player else { return }

        switch abRepeatState {
        case .none:
            pointA = player.currentTime()
            abRepeatState = .settingB
        case .settingB:
            pointB = player.currentTime()
            if let a = pointA, let b = pointB, a < b {
                abRepeatState = .active
                activateABLoop()
            } else {
                // Reset if point B is before point A
                abRepeatState = .none
                pointA = nil
                pointB = nil
            }
        case .active:
            deactivateABLoop()
        }
    }

    private func activateABLoop() {
        guard let player = player, let a = pointA, let b = pointB else { return }
        abRepeatObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: .main) { [weak self] time in
            if self?.isScrubbing == false && time >= b {
                self?.player?.seek(to: a, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    private func deactivateABLoop() {
        if let observer = abRepeatObserver {
            player?.removeTimeObserver(observer)
            abRepeatObserver = nil
        }
        pointA = nil
        pointB = nil
        abRepeatState = .none
    }

    @objc private func handleDoubleTap() {
        // Reset zoom and pan before toggling fit/fill
        view.transform = .identity
        self.panGesture.isEnabled = false
        if let imageView = imageView {
            imageView.contentMode = (imageView.contentMode == .scaleAspectFit) ? .scaleAspectFill : .scaleAspectFit
        } else if let playerLayer = playerLayer {
            playerLayer.videoGravity = (playerLayer.videoGravity == .resizeAspect) ? .resizeAspectFill : .resizeAspect
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1
        } else if gesture.state == .ended {
            // Enable panning only if zoomed in
            self.panGesture.isEnabled = view.transform.a > 1.0
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard view.transform.a > 1 else { return } // Only pan if zoomed
        if gesture.state == .changed {
            let translation = gesture.translation(in: view)
            view.transform = view.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
