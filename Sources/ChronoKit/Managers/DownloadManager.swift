
import Foundation
import os.log

@objc(ChronoKitDownloadManager)
public class DownloadManager: NSObject {

    @objc public static let shared = DownloadManager()

    private var urlSession: URLSession!
    private var activeDownloads: [Int: (MediaMetadata, String)] = [:]
    private var downloadQueue: [(url: URL, metadata: MediaMetadata, format: String)] = []
    private var isDownloading = false
    private var totalDownloadsInBatch = 0
    private var completedDownloadsCount = 0

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.ChronoKit.downloadManager")
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }

    @objc public func downloadFile(url: URL, metadata: MediaMetadata, format: String) {
        os_log("Queuing file for download: %@ with format %@", log: ck_log, type: .default, url.absoluteString, format)
        downloadQueue.append((url, metadata, format))
        totalDownloadsInBatch += 1
        processQueue()
    }

    @objc public func downloadFiles(urls: [URL], metadata: MediaMetadata, formats: [String]) {
        guard urls.count == formats.count else {
            os_log("Error: The number of URLs and formats provided do not match.", log: ck_log, type: .error)
            return
        }
        os_log("Queuing %d files for download.", log: ck_log, type: .default, urls.count)
        totalDownloadsInBatch += urls.count
        for i in 0..<urls.count {
            downloadQueue.append((urls[i], metadata.copyMetadata(), formats[i]))
        }
        processQueue()
    }

    private func processQueue() {
        if isDownloading || downloadQueue.isEmpty {
            return
        }

        isDownloading = true
        let (url, metadata, format) = downloadQueue.removeFirst()

        os_log("Starting download from queue: %@ with format %@", log: ck_log, type: .default, url.absoluteString, format)
        let task = self.urlSession.downloadTask(with: url)
        self.activeDownloads[task.taskIdentifier] = (metadata, format)
        
        DispatchQueue.main.async {
            DownloadUIManager.shared.showProgressView()
            HapticFeedbackManager.shared.playImpact(style: .light)
        }
        
        task.resume()
        os_log("Started download task with identifier: %d", log: ck_log, type: .default, task.taskIdentifier)
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        os_log("[VERBOSE] didFinishDownloadingTo: total=%d, completed=%d, queue=%d, active=%d", log: ck_log, type: .default, self.totalDownloadsInBatch, self.completedDownloadsCount, self.downloadQueue.count, self.activeDownloads.count)
        guard let (metadata, format) = self.activeDownloads.removeValue(forKey: downloadTask.taskIdentifier) else {
            os_log("Error: Could not find metadata for download task %d", log: ck_log, type: .error, downloadTask.taskIdentifier)
            isDownloading = false
            processQueue()
            return
        }

        completedDownloadsCount += 1

        let fileManager = FileManager.default
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        let creatorURL = vaultURL.appendingPathComponent(metadata.authorID)
        let mediaTypeURL = creatorURL.appendingPathComponent(metadata.mediaType == .video ? "Videos" : "Photos")
        let fileName = "\(metadata.itemID)-\(UUID().uuidString).\(format)"
        let destinationURL = mediaTypeURL.appendingPathComponent(fileName)
        os_log("Moving file to: %@", log: ck_log, type: .default, destinationURL.absoluteString)

        do {
            try fileManager.createDirectory(at: mediaTypeURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: location, to: destinationURL)
            metadata.primaryLocalFilePath = destinationURL.path
            os_log("Successfully saved file to: %@", log: ck_log, type: .default, destinationURL.path)
            MediaVaultService.shared.saveMetadata(metadata)
            
            DispatchQueue.main.async {
                HapticFeedbackManager.shared.playSuccess()
                if self.downloadQueue.isEmpty && self.activeDownloads.isEmpty {
                    os_log("[VERBOSE] Resetting counters in didFinishDownloadingTo", log: ck_log, type: .default)
                    DownloadUIManager.shared.hideProgressView()
                    self.totalDownloadsInBatch = 0
                    self.completedDownloadsCount = 0
                }
            }
        } catch {
            os_log("Error moving file: %@", log: ck_log, type: .error, error.localizedDescription)
            DispatchQueue.main.async {
                HapticFeedbackManager.shared.playError()
                if self.downloadQueue.isEmpty && self.activeDownloads.isEmpty {
                    os_log("[VERBOSE] Resetting counters in didFinishDownloadingTo (catch block)", log: ck_log, type: .default)
                    DownloadUIManager.shared.hideProgressView()
                    self.totalDownloadsInBatch = 0
                    self.completedDownloadsCount = 0
                }
            }
        }
        
        isDownloading = false
        processQueue()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let status = "Downloading \(completedDownloadsCount + 1) of \(totalDownloadsInBatch)..."
        DispatchQueue.main.async {
            DownloadUIManager.shared.updateProgress(progress)
            DownloadUIManager.shared.updateStatus(status)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            os_log("[VERBOSE] didCompleteWithError (with error): %@, total=%d, completed=%d, queue=%d, active=%d", log: ck_log, type: .default, error.localizedDescription, self.totalDownloadsInBatch, self.completedDownloadsCount, self.downloadQueue.count, self.activeDownloads.count)
            _ = self.activeDownloads.removeValue(forKey: task.taskIdentifier)
            
            DispatchQueue.main.async {
                HapticFeedbackManager.shared.playError()
                if self.downloadQueue.isEmpty && self.activeDownloads.isEmpty {
                    os_log("[VERBOSE] Resetting counters in didCompleteWithError (with error)", log: ck_log, type: .default)
                    DownloadUIManager.shared.hideProgressView()
                    self.totalDownloadsInBatch = 0
                    self.completedDownloadsCount = 0
                }
            }
        } else {
            os_log("[VERBOSE] didCompleteWithError (success): total=%d, completed=%d, queue=%d, active=%d", log: ck_log, type: .default, self.totalDownloadsInBatch, self.completedDownloadsCount, self.downloadQueue.count, self.activeDownloads.count)
        }
        
        isDownloading = false
        processQueue()
    }
}
