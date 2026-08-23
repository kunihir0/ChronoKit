import Foundation
import UIKit

public class VaultDatabaseService {

    public static let shared = VaultDatabaseService()

    private var db: Connection?

    private let mediaMetadata = Table("media_metadata")
    private let authors = Table("authors")
    private let statistics = Table("statistics")
    private let tags = Table("tags")
    private let media_tags = Table("media_tags")
    private let author_history = Table("author_history")

    // Common
    private let id = Expression<Int64>("id")
    private let media_id = Expression<Int64>("media_id")

    // Media Metadata
    private let itemID = Expression<String>("itemID")
    private let authorID = Expression<String>("authorID")
    private let creationDate = Expression<Date>("creationDate")
    private let downloadDate = Expression<Date>("downloadDate")
    private let caption = Expression<String?>("caption")
    private let mediaType = Expression<Int>("mediaType")
    private let primaryLocalFilePath = Expression<String?>("primaryLocalFilePath")

    // Authors
    private let author_id = Expression<String>("author_id")
    private let author_name = Expression<String?>("author_name")
    private let secUserID = Expression<String?>("secUserID")
    private let customID = Expression<String?>("customID")
    private let signature = Expression<String?>("signature")
    private let bioUrl = Expression<String?>("bioUrl")
    private let bioEmail = Expression<String?>("bioEmail")
    private let awemeCount = Expression<Int?>("awemeCount")
    private let followingCount = Expression<Int?>("followingCount")
    private let followerCount = Expression<Int?>("followerCount")
    private let favoritingCount = Expression<Int?>("favoritingCount")
    private let accountRegion = Expression<String?>("accountRegion")
    private let country = Expression<String?>("country")
    private let province = Expression<String?>("province")
    private let city = Expression<String?>("city")
    private let language = Expression<String?>("language")
    private let isPrivateAccount = Expression<Bool?>("isPrivateAccount")
    private let isProAccount = Expression<Bool?>("isProAccount")
    private let verificationType = Expression<Int?>("verificationType")
    private let shareURL = Expression<String?>("shareURL")
    private let avatarThumbURI = Expression<String?>("avatarThumbURI")
    private let avatarMediumURI = Expression<String?>("avatarMediumURI")
    private let avatarLargerURI = Expression<String?>("avatarLargerURI")

    // Statistics
    private let isFavorite = Expression<Bool>("isFavorite")
    private let width = Expression<Int>("width")
    private let height = Expression<Int>("height")
    private let duration = Expression<TimeInterval>("duration")
    private let fileSize = Expression<Int64>("fileSize")
    private let playCount = Expression<Int?>("playCount")
    private let downloadCount = Expression<Int?>("downloadCount")
    private let shareCount = Expression<Int?>("shareCount")
    private let commentCount = Expression<Int?>("commentCount")
    private let diggCount = Expression<Int?>("diggCount")
    private let favoriteCount = Expression<Int?>("favoriteCount")
    private let vq_score = Expression<Double?>("vq_score")
    private let loudness = Expression<Double?>("loudness")
    private let rec_like_model_score = Expression<Double?>("rec_like_model_score")
    private let rec_finish = Expression<Double?>("rec_finish")
    private let rec_follow = Expression<Double?>("rec_follow")
    private let rec_share = Expression<Double?>("rec_share")
    private let rec_comment = Expression<Double?>("rec_comment")

    // Tags
    private let tag_id = Expression<Int64>("tag_id")
    private let tag_name = Expression<String>("tag_name")

    // Media_tags
    private let media_item_id = Expression<Int64>("media_item_id")

    // Author History
    private let history_id = Expression<Int64>("history_id")
    private let change_date = Expression<Date>("change_date")

    private init() {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let vaultURL = documentsDirectory.appendingPathComponent("ChronoKitVault")

            try fileManager.createDirectory(at: vaultURL, withIntermediateDirectories: true, attributes: nil)

            let dbPath = vaultURL.appendingPathComponent("chronokit.sqlite3").path
            db = try Connection(dbPath)
            try createTables()
            
            // Automatically migrate legacy files to the new encrypted format
            migrateLegacyFiles()
        } catch {
            db = nil
            print("Error initializing database: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        try db.run(authors.create(ifNotExists: true) { t in
            t.column(author_id, primaryKey: true)
            t.column(author_name)
            t.column(secUserID)
            t.column(customID)
            t.column(signature)
            t.column(bioUrl)
            t.column(bioEmail)
            t.column(awemeCount)
            t.column(followingCount)
            t.column(followerCount)
            t.column(favoritingCount)
            t.column(accountRegion)
            t.column(country)
            t.column(province)
            t.column(city)
            t.column(language)
            t.column(isPrivateAccount)
            t.column(isProAccount)
            t.column(verificationType)
            t.column(shareURL)
            t.column(avatarThumbURI)
            t.column(avatarMediumURI)
            t.column(avatarLargerURI)
        })

        try db.run(statistics.create(ifNotExists: true) { t in
            t.column(media_id, primaryKey: true)
            t.column(isFavorite, defaultValue: false)
            t.column(width, defaultValue: 0)
            t.column(height, defaultValue: 0)
            t.column(duration, defaultValue: 0)
            t.column(fileSize, defaultValue: 0)
            t.column(playCount)
            t.column(downloadCount)
            t.column(shareCount)
            t.column(commentCount)
            t.column(diggCount)
            t.column(favoriteCount)
            t.column(vq_score)
            t.column(loudness)
            t.column(rec_like_model_score)
            t.column(rec_finish)
            t.column(rec_follow)
            t.column(rec_share)
            t.column(rec_comment)
            t.foreignKey(media_id, references: mediaMetadata, id, delete: .cascade)
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
            t.column(downloadDate)
            t.column(caption)
            t.column(mediaType)
            t.column(primaryLocalFilePath)
            t.foreignKey(authorID, references: authors, self.author_id)
        })

        try db.run(author_history.create(ifNotExists: true) { t in
            t.column(history_id, primaryKey: .autoincrement)
            t.column(author_id)
            t.column(change_date)
            t.column(author_name)
            t.column(customID)
            t.column(signature)
            t.foreignKey(author_id, references: authors, self.author_id, delete: .cascade)
        })
    }

    public func saveMetadata(metadata: MediaMetadata) throws {
        guard let db = db else { return }

        // Check for author changes and save to history
        let authorQuery = authors.filter(author_id == metadata.authorID)
        if let existingAuthor = try db.pluck(authorQuery) {
            let existingName = existingAuthor[author_name]
            let existingCustomID = existingAuthor[customID]
            let existingSignature = existingAuthor[signature]

            if existingName != metadata.authorName || existingCustomID != metadata.customID || existingSignature != metadata.signature {
                try db.run(author_history.insert(
                    author_id <- metadata.authorID,
                    change_date <- Date(),
                    author_name <- metadata.authorName,
                    customID <- metadata.customID,
                    signature <- metadata.signature
                ))
            }
        }

        try db.run(authors.insert(or: .replace,
            author_id <- metadata.authorID,
            author_name <- metadata.authorName,
            secUserID <- metadata.secUserID,
            customID <- metadata.customID,
            signature <- metadata.signature,
            bioUrl <- metadata.bioUrl,
            bioEmail <- metadata.bioEmail,
            awemeCount <- metadata.awemeCount,
            followingCount <- metadata.followingCount,
            followerCount <- metadata.followerCount,
            favoritingCount <- metadata.favoritingCount,
            accountRegion <- metadata.accountRegion,
            country <- metadata.country,
            province <- metadata.province,
            city <- metadata.city,
            language <- metadata.language,
            isPrivateAccount <- metadata.isPrivateAccount,
            isProAccount <- metadata.isProAccount,
            verificationType <- metadata.verificationType,
            shareURL <- metadata.shareURL,
            avatarThumbURI <- metadata.avatarThumbURI,
            avatarMediumURI <- metadata.avatarMediumURI,
            avatarLargerURI <- metadata.avatarLargerURI
        ))

        let fileManager = FileManager.default
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        let relativePath = metadata.primaryLocalFilePath?.replacingOccurrences(of: vaultURL.path, with: "")

        let insert = mediaMetadata.insert(or: .replace,
            itemID <- metadata.itemID,
            authorID <- metadata.authorID,
            creationDate <- metadata.creationDate,
            downloadDate <- metadata.downloadDate,
            caption <- metadata.caption,
            mediaType <- metadata.mediaType.rawValue,
            primaryLocalFilePath <- relativePath
        )
        let rowid = try db.run(insert)

        try db.run(statistics.insert(or: .replace,
            media_id <- rowid,
            isFavorite <- metadata.isFavorite,
            width <- metadata.width,
            height <- metadata.height,
            duration <- metadata.duration,
            fileSize <- metadata.fileSize,
            playCount <- metadata.playCount,
            downloadCount <- metadata.downloadCount,
            shareCount <- metadata.shareCount,
            commentCount <- metadata.commentCount,
            diggCount <- metadata.diggCount,
            favoriteCount <- metadata.favoriteCount,
            vq_score <- metadata.vq_score,
            loudness <- metadata.loudness,
            rec_like_model_score <- metadata.rec_like_model_score,
            rec_finish <- metadata.rec_finish,
            rec_follow <- metadata.rec_follow,
            rec_share <- metadata.rec_share,
            rec_comment <- metadata.rec_comment
        ))

        for tagName in metadata.tags {
            let tagId = try db.run(tags.insert(or: .ignore, self.tag_name <- tagName))
            try db.run(media_tags.insert(or: .ignore, media_item_id <- rowid, self.tag_id <- tagId))
        }
    }

    public func loadMetadata() throws -> [MediaMetadata] {
        guard let db = db else { return [] }
        var allMetadata: [MediaMetadata] = []
        let query = mediaMetadata.join(authors, on: mediaMetadata[authorID] == authors[author_id]).join(statistics, on: mediaMetadata[id] == statistics[media_id])
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
                downloadDate: row[mediaMetadata[self.downloadDate]],
                caption: row[mediaMetadata[self.caption]],
                mediaType: MediaType(rawValue: row[mediaMetadata[self.mediaType]]) ?? .video,
                primaryLocalFilePath: fullPath,
                isFavorite: row[statistics[self.isFavorite]],
                tags: tagsArray,
                width: row[statistics[self.width]],
                height: row[statistics[self.height]],
                duration: row[statistics[self.duration]],
                fileSize: row[statistics[self.fileSize]],
                secUserID: row[authors[self.secUserID]],
                customID: row[authors[self.customID]],
                signature: row[authors[self.signature]],
                bioUrl: row[authors[self.bioUrl]],
                bioEmail: row[authors[self.bioEmail]],
                awemeCount: row[authors[self.awemeCount]],
                followingCount: row[authors[self.followingCount]],
                followerCount: row[authors[self.followerCount]],
                favoritingCount: row[authors[self.favoritingCount]],
                accountRegion: row[authors[self.accountRegion]],
                country: row[authors[self.country]],
                province: row[authors[self.province]],
                city: row[authors[self.city]],
                language: row[authors[self.language]],
                isPrivateAccount: row[authors[self.isPrivateAccount]],
                isProAccount: row[authors[self.isProAccount]],
                verificationType: row[authors[self.verificationType]],
                shareURL: row[authors[self.shareURL]],
                avatarThumbURI: row[authors[self.avatarThumbURI]],
                avatarMediumURI: row[authors[self.avatarMediumURI]],
                avatarLargerURI: row[authors[self.avatarLargerURI]],
                playCount: row[statistics[self.playCount]],
                downloadCount: row[statistics[self.downloadCount]],
                shareCount: row[statistics[self.shareCount]],
                commentCount: row[statistics[self.commentCount]],
                diggCount: row[statistics[self.diggCount]],
                favoriteCount: row[statistics[self.favoriteCount]],
                vq_score: row[statistics[self.vq_score]],
                loudness: row[statistics[self.loudness]],
                rec_like_model_score: row[statistics[self.rec_like_model_score]],
                rec_finish: row[statistics[self.rec_finish]],
                rec_follow: row[statistics[self.rec_follow]],
                rec_share: row[statistics[self.rec_share]],
                rec_comment: row[statistics[self.rec_comment]]
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

    public func updateFavoriteStatus(for itemID: String, isFavorite: Bool) throws {
        guard let db = db else { return }

        let mediaItem = mediaMetadata.filter(self.itemID == itemID)
        if let media = try db.pluck(mediaItem) {
            let mediaId = media[id]
            let statistic = statistics.filter(media_id == mediaId)
            try db.run(statistic.update(self.isFavorite <- isFavorite))
        }
    }

    public func fetchCreators() throws -> [(authorID: String, authorName: String)] {
        guard let db = db else { return [] }
        var creators: [(authorID: String, authorName: String)] = []
        for row in try db.prepare(authors) {
            creators.append((authorID: row[self.author_id], authorName: row[self.author_name] ?? ""))
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
        var query = mediaMetadata.join(authors, on: mediaMetadata[self.authorID] == authors[author_id]).join(statistics, on: mediaMetadata[id] == statistics[media_id])
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
                downloadDate: row[mediaMetadata[self.downloadDate]],
                caption: row[mediaMetadata[self.caption]],
                mediaType: MediaType(rawValue: row[mediaMetadata[self.mediaType]]) ?? .video,
                primaryLocalFilePath: fullPath,
                isFavorite: row[statistics[self.isFavorite]],
                tags: tagsArray,
                width: row[statistics[self.width]],
                height: row[statistics[self.height]],
                duration: row[statistics[self.duration]],
                fileSize: row[statistics[self.fileSize]],
                secUserID: row[authors[self.secUserID]],
                customID: row[authors[self.customID]],
                signature: row[authors[self.signature]],
                bioUrl: row[authors[self.bioUrl]],
                awemeCount: row[authors[self.awemeCount]],
                followingCount: row[authors[self.followingCount]],
                followerCount: row[authors[self.followerCount]],
                favoritingCount: row[authors[self.favoritingCount]],
                accountRegion: row[authors[self.accountRegion]],
                country: row[authors[self.country]],
                province: row[authors[self.province]],
                city: row[authors[self.city]],
                language: row[authors[self.language]],
                isPrivateAccount: row[authors[self.isPrivateAccount]],
                isProAccount: row[authors[self.isProAccount]],
                verificationType: row[authors[self.verificationType]],
                shareURL: row[authors[self.shareURL]],
                avatarThumbURI: row[authors[self.avatarThumbURI]],
                avatarMediumURI: row[authors[self.avatarMediumURI]],
                avatarLargerURI: row[authors[self.avatarLargerURI]],
                playCount: row[statistics[self.playCount]],
                downloadCount: row[statistics[self.downloadCount]],
                shareCount: row[statistics[self.shareCount]],
                commentCount: row[statistics[self.commentCount]],
                diggCount: row[statistics[self.diggCount]],
                favoriteCount: row[statistics[self.favoriteCount]],
                vq_score: row[statistics[self.vq_score]],
                loudness: row[statistics[self.loudness]],
                rec_like_model_score: row[statistics[self.rec_like_model_score]],
                rec_finish: row[statistics[self.rec_finish]],
                rec_follow: row[statistics[self.rec_follow]],
                rec_share: row[statistics[self.rec_share]],
                rec_comment: row[statistics[self.rec_comment]]
            )
            allMetadata.append(metadata)
        }
        return allMetadata
    }

    public static func wipeAllData() {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let vaultURL = documentsDirectory.appendingPathComponent("ChronoKitVault")
            do {
                try fileManager.removeItem(at: vaultURL)
            } catch {
                print("Error wiping vault: \(error)")
            }
        }
        
        // Also wipe encryption key
        let keyTag = "com.chronokit.encryption.key".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func migrateLegacyFiles() {
        guard let db = db else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fileManager = FileManager.default
            let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
            
            guard fileManager.fileExists(atPath: vaultURL.path) else { return }
            
            let enumerator = fileManager.enumerator(at: vaultURL, includingPropertiesForKeys: nil)
            var filesToMigrate: [URL] = []
            var filesToRecover: [URL] = []
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.hasDirectoryPath { continue }
                if fileURL.lastPathComponent.contains("sqlite") { continue }
                if fileURL.lastPathComponent.contains(".DS_Store") { continue }
                
                let ext = fileURL.pathExtension.lowercased()
                if ext == "mp4" || ext == "jpeg" || ext == "jpg" || ext == "heic" || ext == "png" {
                    filesToMigrate.append(fileURL)
                } else if ext == "" {
                    let relativePath = fileURL.resolvingSymlinksInPath().path.replacingOccurrences(of: vaultURL.resolvingSymlinksInPath().path, with: "")
                    var normalizedPath = relativePath
                    if !normalizedPath.hasPrefix("/") {
                        normalizedPath = "/" + normalizedPath
                    }
                    // Check if this path is in the DB
                    do {
                        let query = self.mediaMetadata.filter(self.primaryLocalFilePath == normalizedPath)
                        if try db.pluck(query) == nil {
                            // It's an orphaned encrypted file!
                            filesToRecover.append(fileURL)
                        }
                    } catch {}
                }
            }
            
            if filesToMigrate.isEmpty && filesToRecover.isEmpty { return }
            
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                   let rootVC = scene.windows.first?.rootViewController {
                    
                    let total = filesToMigrate.count + filesToRecover.count
                    let alert = UIAlertController(title: "Migrating Vault", message: "Securing legacy data... (0/\(total))\nPlease do not close the app.", preferredStyle: .alert)
                    
                    var topController = rootVC
                    while let presented = topController.presentedViewController {
                        topController = presented
                    }
                    topController.present(alert, animated: true, completion: nil)
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.performMigration(files: filesToMigrate, recoveredFiles: filesToRecover, vaultURL: vaultURL, alert: alert, db: db)
                    }
                } else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.performMigration(files: filesToMigrate, recoveredFiles: filesToRecover, vaultURL: vaultURL, alert: nil, db: db)
                    }
                }
            }
        }
    }
    
    private func performMigration(files: [URL], recoveredFiles: [URL], vaultURL: URL, alert: UIAlertController?, db: Connection) {
        let fileManager = FileManager.default
        let totalFiles = files.count + recoveredFiles.count
        var migratedCount = 0
        var processedCount = 0
        
        let processItem = { (fileURL: URL, isRecovered: Bool) in
            let relativePath = fileURL.resolvingSymlinksInPath().path.replacingOccurrences(of: vaultURL.resolvingSymlinksInPath().path, with: "")
            let relativeComponents = relativePath.components(separatedBy: "/").filter { !$0.isEmpty }
            
            if relativeComponents.count >= 3 {
                let authorID = relativeComponents[0]
                let mediaFolder = relativeComponents[1]
                let fileName = relativeComponents[2]
                
                do {
                    var newRelativePath = ""
                    var itemID = ""
                    
                    if !isRecovered {
                        let data = try Data(contentsOf: fileURL)
                        let encryptedData = try EncryptionManager.shared.encrypt(data: data)
                        
                        let newFileName = UUID().uuidString
                        let newFullPathURL = fileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                        
                        newRelativePath = newFullPathURL.resolvingSymlinksInPath().path.replacingOccurrences(of: vaultURL.resolvingSymlinksInPath().path, with: "")
                        if !newRelativePath.hasPrefix("/") {
                            newRelativePath = "/" + newRelativePath
                        }
                        
                        try encryptedData.write(to: newFullPathURL, options: .atomic)
                        try fileManager.removeItem(at: fileURL)
                        
                        itemID = fileName.components(separatedBy: "-").first ?? UUID().uuidString
                    } else {
                        // Already encrypted and extensionless
                        newRelativePath = relativePath
                        if !newRelativePath.hasPrefix("/") {
                            newRelativePath = "/" + newRelativePath
                        }
                        itemID = UUID().uuidString // Since we don't know the itemID, we assign a new UUID so it doesn't conflict
                    }
                    
                    let itemQuery = self.mediaMetadata.filter(self.itemID == itemID)
                    if let _ = try db.pluck(itemQuery) {
                        try db.run(itemQuery.update(self.primaryLocalFilePath <- newRelativePath))
                    } else {
                        let mediaTypeInt = mediaFolder == "Videos" ? MediaType.video.rawValue : MediaType.photoAlbum.rawValue
                        let authorQuery = self.authors.filter(self.author_id == authorID)
                        if try db.pluck(authorQuery) == nil {
                            try db.run(self.authors.insert(or: .ignore,
                                self.author_id <- authorID,
                                self.author_name <- "Recovered Author"
                            ))
                        }
                        
                        let insert = self.mediaMetadata.insert(or: .replace,
                            self.itemID <- itemID,
                            self.authorID <- authorID,
                            self.creationDate <- Date(),
                            self.downloadDate <- Date(),
                            self.caption <- "Recovered File",
                            self.mediaType <- mediaTypeInt,
                            self.primaryLocalFilePath <- newRelativePath
                        )
                        let rowid = try db.run(insert)
                        
                        try db.run(self.statistics.insert(or: .replace,
                            self.media_id <- rowid,
                            self.isFavorite <- false,
                            self.width <- 0,
                            self.height <- 0,
                            self.duration <- 0,
                            self.fileSize <- 0
                        ))
                    }
                    migratedCount += 1
                } catch {
                    print("Migration error for \(fileURL.path): \(error)")
                }
            }
            
            processedCount += 1
            if let alert = alert {
                DispatchQueue.main.async {
                    alert.message = "Securing legacy data... (\(processedCount)/\(totalFiles))\nPlease do not close the app."
                }
            }
        }
        
        for fileURL in files {
            processItem(fileURL, false)
        }
        for fileURL in recoveredFiles {
            processItem(fileURL, true)
        }
        
        if let alert = alert {
            DispatchQueue.main.async {
                alert.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("ChronoKitVaultDidMigrate"), object: nil)
        }
        
        print("Successfully migrated/recovered \(migratedCount) legacy files to encrypted vault.")
    }
}
