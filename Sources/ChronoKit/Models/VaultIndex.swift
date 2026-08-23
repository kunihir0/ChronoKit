import Foundation

public struct AuthorMetadata: Codable {
    public var authorID: String
    public var authorName: String?
    public var secUserID: String?
    // ...
}

public struct VaultIndex: Codable {
    public var items: [MediaMetadata]
    public var authors: [AuthorMetadata]
}
