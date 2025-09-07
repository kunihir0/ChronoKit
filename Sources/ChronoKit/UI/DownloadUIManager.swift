import UIKit

@objc(ChronoKitDownloadUIManager)
public class DownloadUIManager: NSObject {

    @objc public static let shared = DownloadUIManager()

    private var progressView: DownloadProgressView?

    @objc public func showProgressView() {
        if self.progressView == nil,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            self.progressView = DownloadProgressView(frame: .zero)
            self.progressView?.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(self.progressView!)

            NSLayoutConstraint.activate([
                self.progressView!.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                self.progressView!.centerYAnchor.constraint(equalTo: window.centerYAnchor),
                self.progressView!.widthAnchor.constraint(equalToConstant: 200),
                self.progressView!.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }

    @objc public func hideProgressView() {
        self.progressView?.removeFromSuperview()
        self.progressView = nil
    }

    @objc public func updateProgress(_ progress: Float) {
        self.progressView?.setProgress(progress)
    }

    @objc public func updateStatus(_ status: String) {
        self.progressView?.setStatus(status)
    }
}
