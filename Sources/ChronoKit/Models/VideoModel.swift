
import Foundation

public struct VideoModel: Codable {
    public let playURL: URLModel?
    public let downloadURL: URLModel?
    public let duration: TimeInterval?
}
