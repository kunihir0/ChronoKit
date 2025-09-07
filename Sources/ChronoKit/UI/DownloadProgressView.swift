import UIKit

public class DownloadProgressView: UIView {

    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let statusLabel = UILabel()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black.withAlphaComponent(0.5)
        self.layer.cornerRadius = 10

        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.progressView)

        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.textColor = .white
        self.statusLabel.textAlignment = .center
        self.addSubview(self.statusLabel)

        NSLayoutConstraint.activate([
            self.progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.progressView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            self.progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            self.progressView.heightAnchor.constraint(equalToConstant: 5),

            self.statusLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            self.statusLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            self.statusLabel.bottomAnchor.constraint(equalTo: self.progressView.topAnchor, constant: -10)
        ])
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setProgress(_ progress: Float) {
        self.progressView.progress = progress
    }

    public func setStatus(_ status: String) {
        self.statusLabel.text = status
    }
}
