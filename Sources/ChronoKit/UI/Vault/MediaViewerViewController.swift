
import UIKit
import AVKit

class MediaViewerViewController: UIViewController, UIGestureRecognizerDelegate {

    let mediaItem: MediaMetadata
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var imageView: UIImageView?

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
        if mediaItem.mediaType == .video {
            setupVideoPlayer()
        } else {
            setupImageView()
        }

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)

        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.panGesture.delegate = self
        self.panGesture.isEnabled = false
        view.addGestureRecognizer(self.panGesture)
    }

    private func setupImageView() {
        guard let filePath = mediaItem.primaryLocalFilePath, let image = UIImage(contentsOfFile: filePath) else { return }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
        self.imageView = imageView
    }

    private func setupVideoPlayer() {
        guard let filePath = mediaItem.primaryLocalFilePath else { return }
        let videoURL = URL(fileURLWithPath: filePath)
        let playerItem = AVPlayerItem(url: videoURL)

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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleScrubbing(_:)))
        longPressGesture.minimumPressDuration = 0.2
        view.addGestureRecognizer(longPressGesture)

        // Find the double tap gesture to resolve conflicts
        if let doubleTapGesture = view.gestureRecognizers?.first(where: { ($0 as? UITapGestureRecognizer)?.numberOfTapsRequired == 2 }) {
            tapGesture.require(toFail: doubleTapGesture)
        }

        tapGesture.require(toFail: longPressGesture)
        view.addGestureRecognizer(tapGesture)
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
        guard let targetView = imageView ?? view else { return }
        if gesture.state == .changed {
            targetView.transform = targetView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1
        } else if gesture.state == .ended {
            // Enable panning only if zoomed in
            self.panGesture.isEnabled = targetView.transform.a > 1.0
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = imageView ?? view, targetView.transform.a > 1 else { return } // Only pan if zoomed
        if gesture.state == .changed {
            let translation = gesture.translation(in: view)
            targetView.transform = targetView.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
