import Foundation

@objc(ChronoKitMediaMetadata)
public class MediaMetadata: NSObject, Codable, NSCopying {
    @objc public var itemID: String
    @objc public let authorName: String
    @objc public let authorID: String
    @objc public let creationDate: Date
    @objc public let caption: String?
    @objc public let mediaType: MediaType
    @objc public var primaryLocalFilePath: String?
    @objc public var isFavorite: Bool
    @objc public var tags: [String]
    @objc public var width: Int
    @objc public var height: Int
    @objc public var duration: TimeInterval
    @objc public var fileSize: Int64

    @objc public init(itemID: String, authorName: String, authorID: String, creationDate: Date, caption: String?, mediaType: MediaType, primaryLocalFilePath: String?, isFavorite: Bool = false, tags: [String] = [], width: Int = 0, height: Int = 0, duration: TimeInterval = 0, fileSize: Int64 = 0) {
        self.itemID = itemID
        self.authorName = authorName
        self.authorID = authorID
        self.creationDate = creationDate
        self.caption = caption
        self.mediaType = mediaType
        self.primaryLocalFilePath = primaryLocalFilePath
        self.isFavorite = isFavorite
        self.tags = tags
        self.width = width
        self.height = height
        self.duration = duration
        self.fileSize = fileSize
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MediaMetadata(itemID: self.itemID, authorName: self.authorName, authorID: self.authorID, creationDate: self.creationDate, caption: self.caption, mediaType: self.mediaType, primaryLocalFilePath: self.primaryLocalFilePath, isFavorite: self.isFavorite, tags: self.tags, width: self.width, height: self.height, duration: self.duration, fileSize: self.fileSize)
        return copy
    }
}