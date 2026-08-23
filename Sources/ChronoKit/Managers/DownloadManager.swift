import Foundation
import os.log
import AVFoundation
import UIKit

@objc(ChronoKitDownloadManager)
public class DownloadManager: NSObject {

    @objc public static let shared = DownloadManager()

    private var urlSession: URLSession!
    private var activeDownloads: [Int: MediaMetadata] = [:]
    private var activeDataTasks: [Int: Data] = [:]
    private var downloadQueue: [(url: URL, metadata: MediaMetadata)] = []
    private var isDownloading = false
    private var totalDownloadsInBatch = 0
    private var completedDownloadsCount = 0

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.ephemeral
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
        let task = self.urlSession.dataTask(with: url)
        self.activeDownloads[task.taskIdentifier] = metadata
        
        DispatchQueue.main.async {
            DownloadUIManager.shared.showProgressView()
            HapticFeedbackManager.shared.playImpact(style: .light)
        }
        
        task.resume()
        os_log("Started data task with identifier: %d", log: ck_log, type: .default, task.taskIdentifier)
    }
}

extension DownloadManager: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if activeDataTasks[dataTask.taskIdentifier] != nil {
            activeDataTasks[dataTask.taskIdentifier]?.append(data)
        } else {
            activeDataTasks[dataTask.taskIdentifier] = data
        }
        
        let totalBytesWritten = dataTask.countOfBytesReceived
        let totalBytesExpectedToWrite = dataTask.countOfBytesExpectedToReceive
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            let status = "Downloading \(completedDownloadsCount + 1) of \(totalDownloadsInBatch)..."
            DispatchQueue.main.async {
                DownloadUIManager.shared.updateProgress(progress)
                DownloadUIManager.shared.updateStatus(status)
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let accumulatedData = self.activeDataTasks.removeValue(forKey: task.taskIdentifier) ?? Data()
        guard let metadata = self.activeDownloads.removeValue(forKey: task.taskIdentifier) else {
            os_log("Error: Could not find metadata for task %d", log: ck_log, type: .error, task.taskIdentifier)
            isDownloading = false
            processQueue()
            return
        }

        if let error = error {
            os_log("[VERBOSE] didCompleteWithError (with error): %@, total=%d, completed=%d, queue=%d, active=%d", log: ck_log, type: .default, error.localizedDescription, self.totalDownloadsInBatch, self.completedDownloadsCount, self.downloadQueue.count, self.activeDownloads.count)
            
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
            
            completedDownloadsCount += 1

            if let response = task.response as? HTTPURLResponse {
                if UserDefaults.standard.bool(forKey: "log_all_headers") {
                    let logMessage = "Headers for URL: \(task.originalRequest?.url?.absoluteString ?? "N/A")\n\(response.allHeaderFields.description)"
                    FileLogger.shared.log(logMessage)
                }
            }

            let fileManager = FileManager.default
            let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
            let mediaTypeURL = vaultURL.appendingPathComponent("Media")
            
            let fileName = UUID().uuidString
            let destinationURL = mediaTypeURL.appendingPathComponent(fileName)
            os_log("Saving encrypted file to: %@", log: ck_log, type: .default, destinationURL.absoluteString)

            do {
                try fileManager.createDirectory(at: mediaTypeURL, withIntermediateDirectories: true, attributes: nil)
                
                let encryptedData = try EncryptionManager.shared.encrypt(data: accumulatedData)
                try encryptedData.write(to: destinationURL)
                
                // Get media properties
                if metadata.mediaType != .video {
                    if let image = UIImage(data: accumulatedData) {
                        metadata.width = Int(image.size.width * image.scale)
                        metadata.height = Int(image.size.height * image.scale)
                    }
                } else {
                    let customURL = URL(string: "encrypted-video://\(UUID().uuidString)")!
                    let asset = AVURLAsset(url: customURL)
                    let resourceLoaderDelegate = EncryptedVideoResourceLoader(filePath: "Media/\(fileName)")
                    let loaderQueue = DispatchQueue(label: "com.chronokit.download.loader")
                    asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: loaderQueue)
                    
                    let group = DispatchGroup()
                    group.enter()
                    
                    // We must load asynchronously for custom resource loaders to work
                    asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
                        metadata.duration = CMTimeGetSeconds(asset.duration)
                        if let track = asset.tracks(withMediaType: .video).first {
                            let size = track.naturalSize.applying(track.preferredTransform)
                            metadata.width = Int(abs(size.width))
                            metadata.height = Int(abs(size.height))
                        }
                        group.leave()
                    }
                    _ = group.wait(timeout: .now() + 5.0) // Timeout just in case
                }

                metadata.fileSize = Int64(encryptedData.count)
                metadata.primaryLocalFilePath = "Media/\(fileName)"
                os_log("Successfully saved file to: %@", log: ck_log, type: .default, destinationURL.path)
                
                do {
                    VaultJSONService.shared.saveMetadata(metadata: metadata)
                    if let authorName = metadata.authorName {
                        VaultJSONService.shared.saveAuthor(authorID: metadata.authorID, authorName: authorName)
                    }
                } catch {
                    os_log("Error saving metadata to database: %@", log: ck_log, type: .error, error.localizedDescription)
                }


                DispatchQueue.main.async {
                    HapticFeedbackManager.shared.playSuccess()
                    if self.downloadQueue.isEmpty && self.activeDownloads.isEmpty {
                        os_log("[VERBOSE] Resetting counters in didCompleteWithError", log: ck_log, type: .default)
                        DownloadUIManager.shared.hideProgressView()
                        self.totalDownloadsInBatch = 0
                        self.completedDownloadsCount = 0
                    }
                }
            } catch {
                os_log("Error processing/encrypting file: %@", log: ck_log, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    HapticFeedbackManager.shared.playError()
                    if self.downloadQueue.isEmpty && self.activeDownloads.isEmpty {
                        os_log("[VERBOSE] Resetting counters in catch block", log: ck_log, type: .default)
                        DownloadUIManager.shared.hideProgressView()
                        self.totalDownloadsInBatch = 0
                        self.completedDownloadsCount = 0
                    }
                }
            }
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
