import Foundation
import os.log

@objc(ChronoKitURLFilter)
public class URLFilter: NSObject {
    @objc public static let shared = URLFilter()

    @objc public func bestImageURL(from urls: [String]) -> URL? {
        FileLogger.shared.log("[SWIFT] All original URLs: \(urls)")

        // Filter for actual photo URLs
        let photoURLs = urls.filter { url in
            // Explicitly blacklist VVIC urls
            if url.contains("_vvic_") {
                FileLogger.shared.log("[SWIFT] [BLACKLISTED] VVIC URL: \(url)")
                return false
            }

            let isImageType = url.contains(".heic") || url.contains(".webp")
            let isPhotoType = url.contains("~tplv-photomode-image-cover") || url.contains("~tplv-photomode-image-v1")

            return isImageType && isPhotoType
        }
        
        FileLogger.shared.log("[SWIFT] Filtered photo URLs: \(photoURLs)")

        if photoURLs.isEmpty {
            return nil
        }

        // Score the URLs
        var bestURL: String? = nil
        var highestScore = -1

        for urlString in photoURLs {
            var currentScore = 0

            if urlString.contains("~tplv-photomode-image-cover") {
                currentScore += 100
            }
            if urlString.contains("~tplv-photomode-image-v1") {
                currentScore += 100
            }

            if urlString.contains(".heic") {
                currentScore += 110
            }
            if urlString.contains(".jpeg") {
                currentScore += 100
            }
            if urlString.contains(".png") {
                currentScore += 70
            }
            if urlString.contains(".webp") {
                currentScore += 60
            }
            
            FileLogger.shared.log("[SWIFT] URL: \(urlString), Score: \(currentScore)")

            if currentScore > highestScore {
                highestScore = currentScore
                bestURL = urlString
            }
        }

        if let bestURL = bestURL {
            FileLogger.shared.log("[SWIFT] Best URL found: \(bestURL) with score \(highestScore)")
            return URL(string: bestURL)
        }

        return nil
    }

    @objc public func bestVideoURL(from urls: [String], highQuality: Bool) -> URL? {
        FileLogger.shared.log("[SWIFT] Finding best video URL from: \(urls)")
        if highQuality {
            for urlString in urls {
                if urlString.contains("mime_type=video_mp4") && !urlString.contains("api16-normal-useast8.tiktokv.us") {
                    FileLogger.shared.log("[SWIFT] Found high quality video URL: \(urlString)")
                    return URL(string: urlString)
                }
            }
        } else {
            for urlString in urls {
                if !urlString.contains("mime_type=video_mp4") && !urlString.contains("api16-normal-useast8.tiktokv.us") {
                    FileLogger.shared.log("[SWIFT] Found low quality video URL: \(urlString)")
                    return URL(string: urlString)
                }
            }
        }

        if let firstURL = urls.first {
            return URL(string: firstURL)
        }

        return nil
    }
}
