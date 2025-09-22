import UIKit

class VaultItemInfoView: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let authorLabel = UILabel()
    private let captionLabel = UILabel()
    private let statsLabel = UILabel()
    private let dateLabel = UILabel()
    private let favoriteStatusLabel = UILabel()

    private let advancedInfoStackView = UIStackView()
    private let dimensionsLabel = UILabel()
    private let fileSizeLabel = UILabel()
    private let durationLabel = UILabel()
    private let showMoreLabel = UILabel()

    private var isExpanded = false

    var onToggleExpansion: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        [authorLabel, captionLabel, statsLabel, dateLabel, favoriteStatusLabel].forEach { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.numberOfLines = 0
            addSubview(label)
        }

        captionLabel.font = .systemFont(ofSize: 16)
        authorLabel.font = .boldSystemFont(ofSize: 18)
        statsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        dateLabel.font = .systemFont(ofSize: 12)
        favoriteStatusLabel.font = .systemFont(ofSize: 12)

        // Advanced Info
        advancedInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        advancedInfoStackView.axis = .vertical
        advancedInfoStackView.spacing = 8
        advancedInfoStackView.isHidden = true

        [dimensionsLabel, fileSizeLabel, durationLabel].forEach { label in
            label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .white
            advancedInfoStackView.addArrangedSubview(label)
        }

        showMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        showMoreLabel.font = .systemFont(ofSize: 10)
        showMoreLabel.textColor = .lightGray.withAlphaComponent(0.7)
        showMoreLabel.text = "------- tap to show more -------"
        showMoreLabel.textAlignment = .center

        addSubview(advancedInfoStackView)
        addSubview(showMoreLabel)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            authorLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            authorLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            authorLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            captionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 12),
            captionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            captionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            dateLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            statsLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            statsLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            favoriteStatusLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 12),
            favoriteStatusLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            favoriteStatusLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            showMoreLabel.topAnchor.constraint(equalTo: favoriteStatusLabel.bottomAnchor, constant: 8),
            showMoreLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            showMoreLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),

            advancedInfoStackView.topAnchor.constraint(equalTo: showMoreLabel.bottomAnchor, constant: 8),
            advancedInfoStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            advancedInfoStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            advancedInfoStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleExpansion))
        self.addGestureRecognizer(tapGesture)
    }

    @objc private func toggleExpansion() {
        isExpanded.toggle()
        advancedInfoStackView.isHidden = !isExpanded
        showMoreLabel.isHidden = isExpanded
        onToggleExpansion?()
    }

    func configure(with mediaItem: MediaMetadata) {
        authorLabel.text = mediaItem.authorName ?? "Unknown Author"
        captionLabel.text = mediaItem.caption

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let creationString = dateFormatter.string(from: mediaItem.creationDate)
        let downloadString = dateFormatter.string(from: mediaItem.downloadDate)
        dateLabel.text = "Posted: \(creationString)\nDownloaded: \(downloadString)"

        var statsText = ""
        if let plays = mediaItem.playCount {
            statsText += "Plays: \(formatStat(plays))  "
        }
        if let likes = mediaItem.diggCount {
            statsText += "Likes: \(formatStat(likes))  "
        }
        if let comments = mediaItem.commentCount {
            statsText += "Comments: \(formatStat(comments))"
        }
        statsLabel.text = statsText

        if mediaItem.isFavorite {
            favoriteStatusLabel.text = "❤️ Favorited"
            favoriteStatusLabel.textColor = .systemGreen
        } else {
            favoriteStatusLabel.text = "🖤 Not Favorited"
            favoriteStatusLabel.textColor = .systemGray
        }

        // Configure advanced info
        dimensionsLabel.text = "Dimensions: \(mediaItem.width)x\(mediaItem.height)"

        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useMB, .useGB]
        byteFormatter.countStyle = .file
        fileSizeLabel.text = "File Size:  \(byteFormatter.string(fromByteCount: mediaItem.fileSize))"

        if mediaItem.mediaType == .video && mediaItem.duration > 0 {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            durationLabel.text = "Duration:   \(formatter.string(from: mediaItem.duration) ?? "0:00")"
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }
    }

    private func formatStat(_ count: Int) -> String {
        let number = Double(count)
        if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        }
        if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        }
        return "\(count)"
    }
}
