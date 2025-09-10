import Foundation

public class VaultDatabaseService {

    public static let shared = VaultDatabaseService()

    private var db: Connection?

    private let mediaMetadata = Table("media_metadata")
    private let id = Expression<Int64>("id")
    private let itemID = Expression<String>("itemID")
    private let authorName = Expression<String>("authorName")
    private let authorID = Expression<String>("authorID")
    private let creationDate = Expression<Date>("creationDate")
    private let caption = Expression<String?>("caption")
    private let mediaType = Expression<Int>("mediaType")
    private let primaryLocalFilePath = Expression<String?>("primaryLocalFilePath")
    private let isFavorite = Expression<Bool>("isFavorite")
    private let tags = Expression<String>("tags")
    private let width = Expression<Int>("width")
    private let height = Expression<Int>("height")
    private let duration = Expression<TimeInterval>("duration")
    private let fileSize = Expression<Int64>("fileSize")


    private init() {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let vaultURL = documentsDirectory.appendingPathComponent("ChronoKitVault")

            // Create the vault directory if it doesn't exist
            try fileManager.createDirectory(at: vaultURL, withIntermediateDirectories: true, attributes: nil)

            let dbPath = vaultURL.appendingPathComponent("chronokit.sqlite3").path
            db = try Connection(dbPath)
            try createMediaMetadataTable()
        } catch {
            db = nil
            print("Error initializing database: \(error)")
        }
    }

    private func createMediaMetadataTable() throws {
        guard let db = db else { return }
        try db.run(mediaMetadata.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(itemID, unique: true)
            t.column(authorName)
            t.column(authorID)
            t.column(creationDate)
            t.column(caption)
            t.column(mediaType)
            t.column(primaryLocalFilePath)
            t.column(isFavorite, defaultValue: false)
            t.column(tags, defaultValue: "")
            t.column(width, defaultValue: 0)
            t.column(height, defaultValue: 0)
            t.column(duration, defaultValue: 0)
            t.column(fileSize, defaultValue: 0)
        })
    }

    public func saveMetadata(metadata: MediaMetadata) throws {
        guard let db = db else { return }
        let tagsString = metadata.tags.joined(separator: ",")
        let insert = mediaMetadata.insert(or: .replace,
            itemID <- metadata.itemID,
            authorName <- metadata.authorName,
            authorID <- metadata.authorID,
            creationDate <- metadata.creationDate,
            caption <- metadata.caption,
            mediaType <- metadata.mediaType.rawValue,
            primaryLocalFilePath <- metadata.primaryLocalFilePath,
            isFavorite <- metadata.isFavorite,
            tags <- tagsString,
            width <- metadata.width,
            height <- metadata.height,
            duration <- metadata.duration,
            fileSize <- metadata.fileSize
        )
        try db.run(insert)
    }

    public func loadMetadata() throws -> [MediaMetadata] {
        guard let db = db else { return [] }
        var allMetadata: [MediaMetadata] = []
        for row in try db.prepare(mediaMetadata) {
            let tagsArray = row[self.tags].split(separator: ",").map(String.init)
            let metadata = MediaMetadata(
                itemID: row[self.itemID],
                authorName: row[self.authorName],
                authorID: row[self.authorID],
                creationDate: row[self.creationDate],
                caption: row[self.caption],
                mediaType: MediaType(rawValue: row[self.mediaType]) ?? .video,
                primaryLocalFilePath: row[self.primaryLocalFilePath],
                isFavorite: row[self.isFavorite],
                tags: tagsArray,
                width: row[self.width],
                height: row[self.height],
                duration: row[self.duration],
                fileSize: row[self.fileSize]
            )
            allMetadata.append(metadata)
        }
        return allMetadata
    }

    public func deleteMetadata(metadata: MediaMetadata) throws {
        guard let db = db else { return }
        let item = mediaMetadata.filter(itemID == metadata.itemID)
        try db.run(item.delete())
    }

    public func fetchCreators() throws -> [(authorID: String, authorName: String)] {
        guard let db = db else { return [] }
        var creators: [(authorID: String, authorName: String)] = []
        let query = mediaMetadata.select(authorID, authorName).group(authorID)
        for row in try db.prepare(query) {
            creators.append((authorID: row[self.authorID], authorName: row[self.authorName]))
        }
        return creators
    }

    public func getMediaCount(for authorID: String) throws -> Int {
        guard let db = db else { return 0 }
        let query = mediaMetadata.filter(self.authorID == authorID)
        return try db.scalar(query.count)
    }

    public func getTotalMediaCount() throws -> Int {
        guard let db = db else { return 0 }
        return try db.scalar(mediaMetadata.count)
    }

    public func loadMedia(for authorID: String?) throws -> [MediaMetadata] {
        guard let db = db else { return [] }
        var allMetadata: [MediaMetadata] = []
        var query = mediaMetadata
        if let authorID = authorID {
            query = query.filter(self.authorID == authorID)
        }
        for row in try db.prepare(query) {
            let tagsArray = row[self.tags].split(separator: ",").map(String.init)
            let metadata = MediaMetadata(
                itemID: row[self.itemID],
                authorName: row[self.authorName],
                authorID: row[self.authorID],
                creationDate: row[self.creationDate],
                caption: row[self.caption],
                mediaType: MediaType(rawValue: row[self.mediaType]) ?? .video,
                primaryLocalFilePath: row[self.primaryLocalFilePath],
                isFavorite: row[self.isFavorite],
                tags: tagsArray,
                width: row[self.width],
                height: row[self.height],
                duration: row[self.duration],
                fileSize: row[self.fileSize]
            )
            allMetadata.append(metadata)
        }
        return allMetadata
    }
}