import UIKit

class VaultItemCell: UICollectionViewCell {

    let imageView = UIImageView()
    private let heartIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        heartIcon.translatesAutoresizingMaskIntoConstraints = false
        heartIcon.image = UIImage(systemName: "heart.fill")
        heartIcon.tintColor = .white
        heartIcon.isHidden = true
        contentView.addSubview(heartIcon)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            heartIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            heartIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            heartIcon.widthAnchor.constraint(equalToConstant: 20),
            heartIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with mediaItem: MediaMetadata) {
        heartIcon.isHidden = !mediaItem.isFavorite
    }
}
