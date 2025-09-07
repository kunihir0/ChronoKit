
import Foundation

@objc(ChronoKitMediaMetadata)
public class MediaMetadata: NSObject, Codable {
    @objc public let itemID: String
    @objc public let authorName: String
    @objc public let authorID: String
    @objc public let creationDate: Date
    @objc public let caption: String?
    @objc public let mediaType: MediaType
    @objc public var primaryLocalFilePath: String?

    @objc public init(itemID: String, authorName: String, authorID: String, creationDate: Date, caption: String?, mediaType: MediaType, primaryLocalFilePath: String?) {
        self.itemID = itemID
        self.authorName = authorName
        self.authorID = authorID
        self.creationDate = creationDate
        self.caption = caption
        self.mediaType = mediaType
        self.primaryLocalFilePath = primaryLocalFilePath
    }

    @objc public func copyMetadata() -> MediaMetadata {
        return MediaMetadata(itemID: self.itemID, authorName: self.authorName, authorID: self.authorID, creationDate: self.creationDate, caption: self.caption, mediaType: self.mediaType, primaryLocalFilePath: self.primaryLocalFilePath)
    }
}
