import Foundation
import UIKit
import AVFoundation
import os.log

public class ThumbnailService {
    public static let shared = ThumbnailService()
    private let cache = NSCache<NSString, UIImage>()
    
    // Limit concurrency to 2 threads
    private let queue = OperationQueue()
    
    // Hold strong references to resource loaders while generating thumbnails
    private var activeLoaders: [String: EncryptedVideoResourceLoader] = [:]
    private let loadersLock = NSLock()
    
    private init() {
        queue.maxConcurrentOperationCount = 2
    }

    public func getThumbnail(for metadata: MediaMetadata, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: metadata.itemID as NSString) {
            completion(cachedImage)
            return
        }

        queue.addOperation {
            var thumbnail: UIImage?
            if let path = metadata.primaryLocalFilePath {
                if metadata.mediaType == .video {
                    thumbnail = self.generateVideoThumbnail(forPath: path)
                } else {
                    let url = VaultJSONService.shared.getURL(for: path)
                    thumbnail = self.generateImageThumbnail(from: url)
                }
            }

            if let thumbnail = thumbnail {
                self.cache.setObject(thumbnail, forKey: metadata.itemID as NSString)
            }

            DispatchQueue.main.async {
                completion(thumbnail)
            }
        }
    }

    private func generateVideoThumbnail(forPath filePath: String) -> UIImage? {
        let customURL = URL(string: "encrypted-video://\(UUID().uuidString)")!
        let asset = AVURLAsset(url: customURL)
        
        let resourceLoaderDelegate = EncryptedVideoResourceLoader(filePath: filePath)
        let loaderQueue = DispatchQueue(label: "com.chronokit.thumbnail.loader")
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: loaderQueue)
        
        let loaderID = UUID().uuidString
        loadersLock.lock()
        activeLoaders[loaderID] = resourceLoaderDelegate
        loadersLock.unlock()
        
        defer {
            loadersLock.lock()
            activeLoaders.removeValue(forKey: loaderID)
            loadersLock.unlock()
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let timestamp = CMTime(seconds: 0.1, preferredTimescale: 60)
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            return nil
        }
    }

    private func generateImageThumbnail(from url: URL) -> UIImage? {
        do {
            let encryptedData = try Data(contentsOf: url)
            let data = try EncryptionManager.shared.decrypt(data: encryptedData)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
