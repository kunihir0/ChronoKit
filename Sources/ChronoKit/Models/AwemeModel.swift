
import Foundation

public struct AwemeModel: Codable {
    public let video: VideoModel?
    public let photoAlbum: PhotoAlbumModel?
    public let music: MusicModel?
    public let author: UserModel?
    public let statistics: AwemeStatisticsModel?
    public let itemID: String?
    public let createTime: TimeInterval?
    public let region: String?
    public let isAds: Bool?
}
