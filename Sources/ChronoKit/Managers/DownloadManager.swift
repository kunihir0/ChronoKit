import Foundation
import os.log
import AVFoundation
import UIKit

@objc(ChronoKitDownloadManager)
public class DownloadManager: NSObject {

    @objc public static let shared = DownloadManager()

    private var urlSession: URLSession!
    private var activeDownloads: [Int: MediaMetadata] = [:]
    private var downloadQueue: [(url: URL, metadata: MediaMetadata)] = []
    private var isDownloading = false
    private var totalDownloadsInBatch = 0
    private var completedDownloadsCount = 0

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.ChronoKit.downloadManager")
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }

    @objc(downloadFileWithUrl:metadata:)
    public func downloadFile(url: URL, metadata: MediaMetadata) {
        os_log("Queuing file for download: %@", log: ck_log, type: .default, url.absoluteString)
        downloadQueue.append((url, metadata))
        totalDownloadsInBatch += 1
        processQueue()
    }

    @objc(downloadAllURLsWithUrls:metadata:)
    public func downloadAllURLs(urls: [URL], metadata: MediaMetadata) {
        os_log("Queuing %d files for debug download.", log: ck_log, type: .default, urls.count)
        totalDownloadsInBatch += urls.count
        for i in 0..<urls.count {
            let url = urls[i]
            let uniqueMetadata = metadata.copy() as! MediaMetadata
            let urlHash = url.absoluteString.hash
            uniqueMetadata.itemID = "\(uniqueMetadata.itemID)-\(i)-\(urlHash)" // Add index and URL hash to itemID
            downloadQueue.append((url, uniqueMetadata))
        }
        processQueue()
    }

    private func processQueue() {
        if isDownloading || downloadQueue.isEmpty {
            return
        }

        isDownloading = true
        let (url, metadata) = downloadQueue.removeFirst()

        os_log("Starting download from queue: %@", log: ck_log, type: .default, url.absoluteString)
        let task = self.urlSession.downloadTask(with: url)
        self.activeDownloads[task.taskIdentifier] = metadata
        
        DispatchQueue.main.async {
            DownloadUIManager.shared.showProgressView()
            HapticFeedbackManager.shared.playImpact(style: .light)
        }
        
        task.resume()
        os_log("Started download task with identifier: %d", log: ck_log, type: .default, task.taskIdentifier)
    }
    
    private func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/jpeg":
            return "jpeg"
        case "image/png":
            return "png"
        case "image/webp":
            return "webp"
        case "image/heic":
            return "heic"
        case "image/vvic":
            return "vvic"
        case "video/mp4":
            return "mp4"
        default:
            // Fallback to jpeg for unknown image types, or mp4 for others
            if mimeType.hasPrefix("image/") {
                return "jpeg"
            } else {
                return "mp4"
            }
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        os_log("[VERBOSE] didFinishDownloadingTo: total=%d, completed=%d, queue=%d, active=%d", log: ck_log, type: .default, self.totalDownloadsInBatch, self.completedDownloadsCount, self.downloadQueue.count, self.activeDownloads.count)
        guard let metadata = self.activeDownloads.removeValue(forKey: downloadTask.taskIdentifier) else {
            os_log("Error: Could not find metadata for download task %d", log: ck_log, type: .error, downloadTask.taskIdentifier)
            isDownloading = false
            processQueue()
            return
        }

        completedDownloadsCount += 1

        var fileExtension = "tmp"
        if let response = downloadTask.response as? HTTPURLResponse {
            if UserDefaults.standard.bool(forKey: "log_all_headers") {
                let logMessage = "Headers for URL: \(downloadTask.originalRequest?.url?.absoluteString ?? "N/A")\n\(response.allHeaderFields.description)"
                FileLogger.shared.log(logMessage)
            }
            if let mimeType = response.allHeaderFields["Content-Type"] as? String {
                fileExtension = self.fileExtension(for: mimeType)
                os_log("Determined file extension '%@' from MIME type '%@'", log: ck_log, type: .default, fileExtension, mimeType)
            }
        } else {
            os_log("Could not determine MIME type, using temporary extension.", log: ck_log, type: .error)
        }

        let fileManager = FileManager.default
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        let creatorURL = vaultURL.appendingPathComponent(metadata.authorID)
        let mediaTypeURL = creatorURL.appendingPathComponent(metadata.mediaType == .video ? "Videos" : "Photos")
        let fileName = "\(metadata.itemID)-\(UUID().uuidString).\(fileExtension)"
        let destinationURL = mediaTypeURL.appendingPathComponent(fileName)
        os_log("Moving file to: %@", log: ck_log, type: .default, destinationURL.absoluteString)

        do {
            try fileManager.createDirectory(at: mediaTypeURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: location, to: destinationURL)

            // Get file attributes and media properties
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                if let size = fileAttributes[.size] as? NSNumber {
                    metadata.fileSize = size.int64Value
                }
            } catch {
                os_log("Error getting file size: %@", log: ck_log, type: .error, error.localizedDescription)
            }

            if metadata.mediaType == .video {
                let asset = AVURLAsset(url: destinationURL)
                metadata.duration = CMTimeGetSeconds(asset.duration)
                if let track = asset.tracks(withMediaType: .video).first {
                    let size = track.naturalSize.applying(track.preferredTransform)
                    metadata.width = Int(abs(size.width))
                    metadata.height = Int(abs(size.height))
                }
            } else { // Photo
                if let image = UIImage(contentsOfFile: destinationURL.path) {
                    metadata.width = Int(image.size.width * image.scale)
                    metadata.height = Int(image.size.height * image.scale)
                }
            }

            metadata.primaryLocalFilePath = destinationURL.path
            os_log("Successfully saved file to: %@", log: ck_log, type: .default, destinationURL.path)
            do {
                try VaultDatabaseService.shared.saveMetadata(metadata: metadata)
            } catch {
                os_log("Error saving metadata to database: %@", log: ck_log, type: .error, error.localizedDescription)
            }

            // Debug: Save a copy of the downloaded image
            if metadata.mediaType != .video {
                let debugURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("debug")
                try? fileManager.createDirectory(at: debugURL, withIntermediateDirectories: true, attributes: nil)
                let debugFileURL = debugURL.appendingPathComponent("last_downloaded_image.\(fileExtension)")
                if fileManager.fileExists(atPath: debugFileURL.path) {
                    try? fileManager.removeItem(at: debugFileURL)
                }
                try? fileManager.copyItem(at: destinationURL, to: debugFileURL)
                os_log("Saved a debug copy of the image to %@", log: ck_log, type: .default, debugFileURL.path)
            }
            
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

    @objc(downloadContentWithItemID:authorName:authorID:creationDate:caption:mediaType:urlLists:secUserID:customID:signature:bioUrl:awemeCount:followingCount:followerCount:favoritingCount:accountRegion:country:province:city:language:isPrivateAccount:isProAccount:verificationType:shareURL:avatarThumbURI:avatarMediumURI:avatarLargerURI:playCount:downloadCount:shareCount:commentCount:diggCount:favoriteCount:)
    public func downloadContent(itemID: String, authorName: String, authorID: String, creationDate: Date, caption: String?, mediaType: MediaType, urlLists: [[String]], secUserID: String?, customID: String?, signature: String?, bioUrl: String?, awemeCount: NSNumber?, followingCount: NSNumber?, followerCount: NSNumber?, favoritingCount: NSNumber?, accountRegion: String?, country: String?, province: String?, city: String?, language: String?, isPrivateAccount: Bool, isProAccount: Bool, verificationType: NSNumber?, shareURL: String?, avatarThumbURI: String?, avatarMediumURI: String?, avatarLargerURI: String?, playCount: NSNumber?, downloadCount: NSNumber?, shareCount: NSNumber?, commentCount: NSNumber?, diggCount: NSNumber?, favoriteCount: NSNumber?) {
        os_log("Starting download for itemID: %@", log: ck_log, type: .default, itemID)

        let metadata = MediaMetadata(itemID: itemID, authorName: authorName, authorID: authorID, creationDate: creationDate, downloadDate: Date(), caption: caption, mediaType: mediaType, primaryLocalFilePath: nil, isFavorite: false, tags: [], width: 0, height: 0, duration: 0, fileSize: 0, secUserID: secUserID, customID: customID, signature: signature, bioUrl: bioUrl, awemeCount: awemeCount?.intValue, followingCount: followingCount?.intValue, followerCount: followerCount?.intValue, favoritingCount: favoritingCount?.intValue, accountRegion: accountRegion, country: country, province: province, city: city, language: language, isPrivateAccount: isPrivateAccount, isProAccount: isProAccount, verificationType: verificationType?.intValue, shareURL: shareURL, avatarThumbURI: avatarThumbURI, avatarMediumURI: avatarMediumURI, avatarLargerURI: avatarLargerURI, playCount: playCount?.intValue, downloadCount: downloadCount?.intValue, shareCount: shareCount?.intValue, commentCount: commentCount?.intValue, diggCount: diggCount?.intValue, favoriteCount: favoriteCount?.intValue)

        if mediaType == .video {
            guard let originURLList = urlLists.first else {
                os_log("Video URL list is empty", log: ck_log, type: .error)
                DispatchQueue.main.async { DownloadUIManager.shared.hideProgressView() }
                return
            }
            
            let highQuality = UserDefaults.standard.bool(forKey: "high_quality")
            if let videoURL = URLFilter.shared.bestVideoURL(from: originURLList, highQuality: highQuality) {
                os_log("Initiating video download.", log: ck_log, type: .default)
                self.downloadFile(url: videoURL, metadata: metadata)
            } else {
                DispatchQueue.main.async { DownloadUIManager.shared.hideProgressView() }
            }
        } else if mediaType == .photoAlbum {
            os_log("Found %lu photos in album.", log: ck_log, type: .default, urlLists.count)
            var didQueueDownload = false

            for (i, originURLList) in urlLists.enumerated() {
                let uniqueItemID = "\(itemID)-\(i)"
                let photoMetadata = metadata.copy() as! MediaMetadata
                photoMetadata.itemID = uniqueItemID

                if UserDefaults.standard.bool(forKey: "debug_download_all_urls") {
                    let urlsToDownload = originURLList.compactMap { urlString -> URL? in
                        if urlString.contains("_vvic_") { return nil }
                        return URL(string: urlString)
                    }
                    if !urlsToDownload.isEmpty {
                        self.downloadAllURLs(urls: urlsToDownload, metadata: photoMetadata)
                        didQueueDownload = true
                    }
                } else {
                    let urlsToDownload = originURLList.compactMap { urlString -> URL? in
                        if urlString.contains("_vvic_") { return nil }
                        return URL(string: urlString)
                    }
                    if !urlsToDownload.isEmpty {
                        self.downloadAllURLs(urls: urlsToDownload, metadata: photoMetadata)
                        didQueueDownload = true
                    }
                }
            }

            if !didQueueDownload {
                DispatchQueue.main.async { DownloadUIManager.shared.hideProgressView() }
            }
        }
    }
}
