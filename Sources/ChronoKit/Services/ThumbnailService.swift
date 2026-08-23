import UIKit
import AVFoundation
import os.log

public class ThumbnailService {

    public static let shared = ThumbnailService()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    public func getThumbnail(for metadata: MediaMetadata, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: metadata.itemID as NSString) {
            completion(cachedImage)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var thumbnail: UIImage?
            if let path = metadata.primaryLocalFilePath {
                let url = URL(fileURLWithPath: path)
                if metadata.mediaType == .video {
                    thumbnail = self.generateVideoThumbnail(from: url)
                } else {
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

    private func generateVideoThumbnail(from url: URL) -> UIImage? {
        do {
            let encryptedData = try Data(contentsOf: url)
            let decryptedData = try EncryptionManager.shared.decrypt(data: encryptedData)
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            try decryptedData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            let asset = AVAsset(url: tempURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            let duration = asset.duration
            let durationInSeconds = CMTimeGetSeconds(duration)
            let timestamp = CMTime(seconds: durationInSeconds * 0.1, preferredTimescale: 60)
            
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            os_log("Error generating video thumbnail: %@", log: ck_log, type: .error, error.localizedDescription)
            return nil
        }
    }

    private func generateImageThumbnail(from url: URL) -> UIImage? {
        do {
            let encryptedData = try Data(contentsOf: url)
            let data = try EncryptionManager.shared.decrypt(data: encryptedData)
            let image = UIImage(data: data)
            if image == nil {
                os_log("Error: UIImage(data:) returned nil for %@", log: ck_log, type: .error, url.absoluteString)
            }
            return image
        } catch {
            os_log("Error loading image data: %@", log: ck_log, type: .error, error.localizedDescription)
            return nil
        }
    }
}
