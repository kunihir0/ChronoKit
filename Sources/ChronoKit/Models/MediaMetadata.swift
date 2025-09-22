import Foundation

@objc(ChronoKitMediaMetadata)
public class MediaMetadata: NSObject, Codable, NSCopying {
    @objc public var itemID: String
    @objc public let authorName: String?
    @objc public let authorID: String
    @objc public let creationDate: Date
    @objc public let downloadDate: Date
    @objc public let caption: String?
    @objc public let mediaType: MediaType
    @objc public var primaryLocalFilePath: String?
    @objc public var isFavorite: Bool
    @objc public var tags: [String]
    @objc public var width: Int
    @objc public var height: Int
    @objc public var duration: TimeInterval
    @objc public var fileSize: Int64

    // Author
    public let secUserID: String?
    public let customID: String?
    public let signature: String?
    public let bioUrl: String?
    public let bioEmail: String?
    public let awemeCount: Int?
    public let followingCount: Int?
    public let followerCount: Int?
    public let favoritingCount: Int?
    public let accountRegion: String?
    public let country: String?
    public let province: String?
    public let city: String?
    public let language: String?
    public let isPrivateAccount: Bool?
    public let isProAccount: Bool?
    public let verificationType: Int?
    public let shareURL: String?
    public let avatarThumbURI: String?
    public let avatarMediumURI: String?
    public let avatarLargerURI: String?

    // Statistics
    public let playCount: Int?
    public let downloadCount: Int?
    public let shareCount: Int?
    public let commentCount: Int?
    public let diggCount: Int?
    public let favoriteCount: Int?
    public let vq_score: Double?
    public let loudness: Double?
    public let rec_like_model_score: Double?
    public let rec_finish: Double?
    public let rec_follow: Double?
    public let rec_share: Double?
    public let rec_comment: Double?



    public init(itemID: String, authorName: String?, authorID: String, creationDate: Date, downloadDate: Date, caption: String?, mediaType: MediaType, primaryLocalFilePath: String?, isFavorite: Bool = false, tags: [String] = [], width: Int = 0, height: Int = 0, duration: TimeInterval = 0, fileSize: Int64 = 0, secUserID: String? = nil, customID: String? = nil, signature: String? = nil, bioUrl: String? = nil, bioEmail: String? = nil, awemeCount: Int? = nil, followingCount: Int? = nil, followerCount: Int? = nil, favoritingCount: Int? = nil, accountRegion: String? = nil, country: String? = nil, province: String? = nil, city: String? = nil, language: String? = nil, isPrivateAccount: Bool? = nil, isProAccount: Bool? = nil, verificationType: Int? = nil, shareURL: String? = nil, avatarThumbURI: String? = nil, avatarMediumURI: String? = nil, avatarLargerURI: String? = nil, playCount: Int? = nil, downloadCount: Int? = nil, shareCount: Int? = nil, commentCount: Int? = nil, diggCount: Int? = nil, favoriteCount: Int? = nil, vq_score: Double? = nil, loudness: Double? = nil, rec_like_model_score: Double? = nil, rec_finish: Double? = nil, rec_follow: Double? = nil, rec_share: Double? = nil, rec_comment: Double? = nil) {
        self.itemID = itemID
        self.authorName = authorName
        self.authorID = authorID
        self.creationDate = creationDate
        self.downloadDate = downloadDate
        self.caption = caption
        self.mediaType = mediaType
        self.primaryLocalFilePath = primaryLocalFilePath
        self.isFavorite = isFavorite
        self.tags = tags
        self.width = width
        self.height = height
        self.duration = duration
        self.fileSize = fileSize
        self.secUserID = secUserID
        self.customID = customID
        self.signature = signature
        self.bioUrl = bioUrl
        self.bioEmail = bioEmail
        self.awemeCount = awemeCount
        self.followingCount = followingCount
        self.followerCount = followerCount
        self.favoritingCount = favoritingCount
        self.accountRegion = accountRegion
        self.country = country
        self.province = province
        self.city = city
        self.language = language
        self.isPrivateAccount = isPrivateAccount
        self.isProAccount = isProAccount
        self.verificationType = verificationType
        self.shareURL = shareURL
        self.avatarThumbURI = avatarThumbURI
        self.avatarMediumURI = avatarMediumURI
        self.avatarLargerURI = avatarLargerURI
        self.playCount = playCount
        self.downloadCount = downloadCount
        self.shareCount = shareCount
        self.commentCount = commentCount
        self.diggCount = diggCount
        self.favoriteCount = favoriteCount
        self.vq_score = vq_score
        self.loudness = loudness
        self.rec_like_model_score = rec_like_model_score
        self.rec_finish = rec_finish
        self.rec_follow = rec_follow
        self.rec_share = rec_share
        self.rec_comment = rec_comment
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MediaMetadata(itemID: self.itemID, authorName: self.authorName, authorID: self.authorID, creationDate: self.creationDate, downloadDate: self.downloadDate, caption: self.caption, mediaType: self.mediaType, primaryLocalFilePath: self.primaryLocalFilePath, isFavorite: self.isFavorite, tags: self.tags, width: self.width, height: self.height, duration: self.duration, fileSize: self.fileSize, secUserID: self.secUserID, customID: self.customID, signature: self.signature, bioUrl: self.bioUrl, bioEmail: self.bioEmail, awemeCount: self.awemeCount, followingCount: self.followingCount, followerCount: self.followerCount, favoritingCount: self.favoritingCount, accountRegion: self.accountRegion, country: self.country, province: self.province, city: self.city, language: self.language, isPrivateAccount: self.isPrivateAccount, isProAccount: self.isProAccount, verificationType: self.verificationType, shareURL: self.shareURL, avatarThumbURI: self.avatarThumbURI, avatarMediumURI: self.avatarMediumURI, avatarLargerURI: self.avatarLargerURI, playCount: self.playCount, downloadCount: self.downloadCount, shareCount: self.shareCount, commentCount: self.commentCount, diggCount: self.diggCount, favoriteCount: self.favoriteCount, vq_score: self.vq_score, loudness: self.loudness, rec_like_model_score: self.rec_like_model_score, rec_finish: self.rec_finish, rec_follow: self.rec_follow, rec_share: self.rec_share, rec_comment: self.rec_comment)
        return copy
    }
}