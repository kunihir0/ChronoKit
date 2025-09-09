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
        })
    }

    public func saveMetadata(metadata: MediaMetadata) throws {
        guard let db = db else { return }
        let insert = mediaMetadata.insert(or: .replace,
            itemID <- metadata.itemID,
            authorName <- metadata.authorName,
            authorID <- metadata.authorID,
            creationDate <- metadata.creationDate,
            caption <- metadata.caption,
            mediaType <- metadata.mediaType.rawValue,
            primaryLocalFilePath <- metadata.primaryLocalFilePath
        )
        try db.run(insert)
    }

    public func loadMetadata() throws -> [MediaMetadata] {
        guard let db = db else { return [] }
        var allMetadata: [MediaMetadata] = []
        for row in try db.prepare(mediaMetadata) {
            let metadata = MediaMetadata(
                itemID: row[itemID],
                authorName: row[authorName],
                authorID: row[authorID],
                creationDate: row[creationDate],
                caption: row[caption],
                mediaType: MediaType(rawValue: row[mediaType]) ?? .video,
                primaryLocalFilePath: row[primaryLocalFilePath]
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
}
