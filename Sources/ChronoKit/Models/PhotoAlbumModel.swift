
import Foundation

public struct PhotoAlbumModel: Codable {
    public let photos: [PhotoAlbumPhotoModel]?
}

public struct PhotoAlbumPhotoModel: Codable {
    public let originPhotoURL: URLModel?
}
