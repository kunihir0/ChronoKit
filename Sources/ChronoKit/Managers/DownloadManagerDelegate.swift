import Foundation

public protocol DownloadManagerDelegate: AnyObject {
    func downloadManager(didUpdateProgress progress: Float)
    func downloadManager(didFinishDownload withError: Error?)
}
