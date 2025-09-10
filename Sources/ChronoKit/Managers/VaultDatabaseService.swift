import Foundation

public class VaultDatabaseService {

    public static let shared = VaultDatabaseService()

    private var db: Connection?

    private let mediaMetadata = Table("media_metadata")
    private let authors = Table("authors")
    private let tags = Table("tags")
    private let media_tags = Table("media_tags")
    private let id = Expression<Int64>("id")
    private let itemID = Expression<String>("itemID")
    private let authorName = Expression<String>("authorName")
    private let authorID = Expression<String>("authorID")
    private let creationDate = Expression<Date>("creationDate")
    private let caption = Expression<String?>("caption")
    private let mediaType = Expression<Int>("mediaType")
    private let primaryLocalFilePath = Expression<String?>("primaryLocalFilePath")
    private let isFavorite = Expression<Bool>("isFavorite")
    private let width = Expression<Int>("width")
    private let height = Expression<Int>("height")
    private let duration = Expression<TimeInterval>("duration")
    private let fileSize = Expression<Int64>("fileSize")

    // Authors table columns
    private let author_id = Expression<String>("author_id")
    private let author_name = Expression<String>("author_name")

    // Tags table columns
    private let tag_id = Expression<Int64>("tag_id")
    private let tag_name = Expression<String>("tag_name")

    // Media_tags table columns
    private let media_item_id = Expression<Int64>("media_item_id")


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

        try db.run(authors.create(ifNotExists: true) { t in
            t.column(author_id, primaryKey: true)
            t.column(author_name)
        })

        try db.run(tags.create(ifNotExists: true) { t in
            t.column(tag_id, primaryKey: .autoincrement)
            t.column(tag_name, unique: true)
        })

        try db.run(media_tags.create(ifNotExists: true) { t in
            t.column(media_item_id)
            t.column(tag_id)
            t.primaryKey(media_item_id, tag_id)
            t.foreignKey(media_item_id, references: mediaMetadata, id, delete: .cascade)
            t.foreignKey(tag_id, references: tags, self.tag_id, delete: .cascade)
        })

        try db.run(mediaMetadata.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(itemID, unique: true)
            t.column(authorID)
            t.column(creationDate)
            t.column(caption)
            t.column(mediaType)
            t.column(primaryLocalFilePath)
            t.column(isFavorite, defaultValue: false)
            t.column(width, defaultValue: 0)
            t.column(height, defaultValue: 0)
            t.column(duration, defaultValue: 0)
            t.column(fileSize, defaultValue: 0)
            t.foreignKey(authorID, references: authors, self.author_id)
        })
    }

    public func saveMetadata(metadata: MediaMetadata) throws {
        guard let db = db else { return }

        // Insert author if they don't exist
        try db.run(authors.insert(or: .ignore, author_id <- metadata.authorID, author_name <- metadata.authorName))

        let fileManager = FileManager.default
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        let relativePath = metadata.primaryLocalFilePath?.replacingOccurrences(of: vaultURL.path, with: "")

        let insert = mediaMetadata.insert(or: .replace,
            itemID <- metadata.itemID,
            authorID <- metadata.authorID,
            creationDate <- metadata.creationDate,
            caption <- metadata.caption,
            mediaType <- metadata.mediaType.rawValue,
            primaryLocalFilePath <- relativePath,
            isFavorite <- metadata.isFavorite,
            width <- metadata.width,
            height <- metadata.height,
            duration <- metadata.duration,
            fileSize <- metadata.fileSize
        )
        let rowid = try db.run(insert)

        // Handle tags
        for tagName in metadata.tags {
            let tagId = try db.run(tags.insert(or: .ignore, self.tag_name <- tagName))
            try db.run(media_tags.insert(or: .ignore, media_item_id <- rowid, self.tag_id <- tagId))
        }
    }

    public func loadMetadata() throws -> [MediaMetadata] {
        guard let db = db else { return [] }
        var allMetadata: [MediaMetadata] = []
        let query = mediaMetadata.join(authors, on: mediaMetadata[authorID] == authors[author_id])
        for row in try db.prepare(query) {
            let mediaId = row[mediaMetadata[self.id]]
            let tagsQuery = media_tags.join(tags, on: media_tags[tag_id] == tags[self.tag_id]).filter(media_tags[media_item_id] == mediaId)
            let tagsArray = try db.prepare(tagsQuery).map { $0[tags[self.tag_name]] }

            let fileManager = FileManager.default
            let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
            let relativePath = row[mediaMetadata[self.primaryLocalFilePath]]
            let fullPath = relativePath != nil ? vaultURL.appendingPathComponent(relativePath!).path : nil

            let metadata = MediaMetadata(
                itemID: row[mediaMetadata[self.itemID]],
                authorName: row[authors[self.author_name]],
                authorID: row[mediaMetadata[self.authorID]],
                creationDate: row[mediaMetadata[self.creationDate]],
                caption: row[mediaMetadata[self.caption]],
                mediaType: MediaType(rawValue: row[mediaMetadata[self.mediaType]]) ?? .video,
                primaryLocalFilePath: fullPath,
                isFavorite: row[mediaMetadata[self.isFavorite]],
                tags: tagsArray,
                width: row[mediaMetadata[self.width]],
                height: row[mediaMetadata[self.height]],
                duration: row[mediaMetadata[self.duration]],
                fileSize: row[mediaMetadata[self.fileSize]]
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
        for row in try db.prepare(authors) {
            creators.append((authorID: row[self.author_id], authorName: row[self.author_name]))
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
        var query = mediaMetadata.join(authors, on: mediaMetadata[self.authorID] == authors[author_id])
        if let authorID = authorID {
            query = query.filter(mediaMetadata[self.authorID] == authorID)
        }
        for row in try db.prepare(query) {
            let mediaId = row[mediaMetadata[self.id]]
            let tagsQuery = media_tags.join(tags, on: media_tags[tag_id] == tags[self.tag_id]).filter(media_tags[media_item_id] == mediaId)
            let tagsArray = try db.prepare(tagsQuery).map { $0[tags[self.tag_name]] }

            let fileManager = FileManager.default
            let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
            let relativePath = row[mediaMetadata[self.primaryLocalFilePath]]
            let fullPath = relativePath != nil ? vaultURL.appendingPathComponent(relativePath!).path : nil

            let metadata = MediaMetadata(
                itemID: row[mediaMetadata[self.itemID]],
                authorName: row[authors[self.author_name]],
                authorID: row[mediaMetadata[self.authorID]],
                creationDate: row[mediaMetadata[self.creationDate]],
                caption: row[mediaMetadata[self.caption]],
                mediaType: MediaType(rawValue: row[mediaMetadata[self.mediaType]]) ?? .video,
                primaryLocalFilePath: fullPath,
                isFavorite: row[mediaMetadata[self.isFavorite]],
                tags: tagsArray,
                width: row[mediaMetadata[self.width]],
                height: row[mediaMetadata[self.height]],
                duration: row[mediaMetadata[self.duration]],
                fileSize: row[mediaMetadata[self.fileSize]]
            )
            allMetadata.append(metadata)
        }
        return allMetadata
    }
}