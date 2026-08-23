import Foundation

@objc(ChronoKitVaultJSONService)
public class VaultJSONService: NSObject {
    public static let shared = VaultJSONService()
    
    private let fileManager = FileManager.default
    private var indexURL: URL {
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        return vaultURL.appendingPathComponent("vault_index.enc")
    }
    
    private var index: VaultIndex
    private let queue = DispatchQueue(label: "com.kunihir0.chronokit.jsonqueue")
    
    override init() {
        self.index = VaultIndex(items: [], authors: [])
        super.init()
        loadIndex()
        migrateFromSQLiteIfNeeded()
    }
    
    private func loadIndex() {
        do {
            if fileManager.fileExists(atPath: indexURL.path) {
                let data = try Data(contentsOf: indexURL)
                let decrypted = try EncryptionManager.shared.decrypt(data: data)
                self.index = try JSONDecoder().decode(VaultIndex.self, from: decrypted)
            }
        } catch {
            print("Failed to load or decrypt VaultIndex: \(error)")
        }
    }
    
    private func saveIndex() {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let encoded = try JSONEncoder().encode(self.index)
                let encrypted = try EncryptionManager.shared.encrypt(data: encoded)
                try encrypted.write(to: self.indexURL, options: .atomic)
            } catch {
                print("Failed to encrypt and save VaultIndex: \(error)")
            }
        }
    }
    
    // CRUD Operations
    public func fetchCreators() -> [(authorID: String, authorName: String)] {
        return queue.sync {
            return index.authors.map { ($0.authorID, $0.authorName ?? "Unknown") }
        }
    }
    
    public func getTotalMediaCount() -> Int {
        return queue.sync { index.items.count }
    }
    
    public func getMediaCount(for authorID: String) -> Int {
        return queue.sync { index.items.filter { $0.authorID == authorID }.count }
    }
    
    public func loadMedia(for creatorID: String?) -> [MediaMetadata] {
        return queue.sync {
            if let id = creatorID {
                return index.items.filter { $0.authorID == id }
            }
            return index.items
        }
    }
    
    public func saveMetadata(metadata: MediaMetadata) {
        queue.sync {
            if let idx = index.items.firstIndex(where: { $0.itemID == metadata.itemID }) {
                index.items[idx] = metadata
            } else {
                index.items.append(metadata)
            }
        }
        saveIndex()
    }
    
    public func saveAuthor(authorID: String, authorName: String) {
        queue.sync {
            if !index.authors.contains(where: { $0.authorID == authorID }) {
                index.authors.append(AuthorMetadata(authorID: authorID, authorName: authorName, secUserID: nil))
            }
        }
        saveIndex()
    }
    
    public func updateFavoriteStatus(for itemID: String, isFavorite: Bool) {
        queue.sync {
            if let idx = index.items.firstIndex(where: { $0.itemID == itemID }) {
                index.items[idx].isFavorite = isFavorite
            }
        }
        saveIndex()
    }
    
    public func deleteItem(itemID: String) {
        queue.sync {
            if let idx = index.items.firstIndex(where: { $0.itemID == itemID }) {
                if let path = index.items[idx].primaryLocalFilePath {
                    let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
                    let fullPath = vaultURL.appendingPathComponent(path)
                    try? fileManager.removeItem(at: fullPath)
                }
                index.items.remove(at: idx)
            }
        }
        saveIndex()
    }
}

extension VaultJSONService {
    public func migrateFromSQLiteIfNeeded() {
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        let dbURL = vaultURL.appendingPathComponent("chronokit.sqlite3")
        let mediaDir = vaultURL.appendingPathComponent("Media")
        
        guard fileManager.fileExists(atPath: dbURL.path) else { return }
        
        print("Starting SQLite to JSON Migration...")
        
        do {
            try fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true, attributes: nil)
            let oldItems = (try? VaultDatabaseService.shared.loadMedia(for: nil)) ?? []
            let oldCreators = (try? VaultDatabaseService.shared.fetchCreators()) ?? []
            
            queue.sync {
                self.index.authors = oldCreators.map { AuthorMetadata(authorID: $0.authorID, authorName: $0.authorName, secUserID: nil) }
                self.index.items = []
                
                var migratedPaths = Set<String>()
                
                for item in oldItems {
                    if let oldPath = item.primaryLocalFilePath {
                        let oldFullPath = URL(fileURLWithPath: oldPath).resolvingSymlinksInPath()
                        if fileManager.fileExists(atPath: oldFullPath.path) {
                            let newFileName = UUID().uuidString
                            let newFullPath = mediaDir.appendingPathComponent(newFileName)
                            
                            do {
                                try fileManager.moveItem(at: oldFullPath, to: newFullPath)
                                item.primaryLocalFilePath = "Media/\(newFileName)"
                                self.index.items.append(item)
                                migratedPaths.insert(oldFullPath.path)
                            } catch {
                                print("Failed to move file \(oldFullPath.path) to \(newFullPath.path): \(error)")
                            }
                        }
                    }
                }
                
                if let enumerator = fileManager.enumerator(at: vaultURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.lastPathComponent.contains("sqlite") || fileURL.lastPathComponent.contains(".DS_Store") || fileURL.path.contains("/Media/") { continue }
                        if fileURL.pathExtension == "" {
                            let oldFullPath = fileURL.resolvingSymlinksInPath()
                            if !migratedPaths.contains(oldFullPath.path) {
                                let relativePath = oldFullPath.path.replacingOccurrences(of: vaultURL.resolvingSymlinksInPath().path, with: "")
                                let components = relativePath.components(separatedBy: "/").filter { !$0.isEmpty }
                                
                                if components.count >= 3 {
                                    let authorID = components[0]
                                    let mediaFolder = components[1]
                                    let newFileName = UUID().uuidString
                                    let newFullPath = mediaDir.appendingPathComponent(newFileName)
                                    
                                    do {
                                        try fileManager.moveItem(at: oldFullPath, to: newFullPath)
                                        let mediaType = mediaFolder == "Videos" ? MediaType.video : MediaType.photoAlbum
                                        let newItem = MediaMetadata(
                                            itemID: UUID().uuidString,
                                            authorName: "Recovered Author",
                                            authorID: authorID,
                                            creationDate: Date(),
                                            downloadDate: Date(),
                                            caption: "Recovered File",
                                            mediaType: mediaType,
                                            primaryLocalFilePath: "Media/\(newFileName)"
                                        )
                                        self.index.items.append(newItem)
                                        if !self.index.authors.contains(where: { $0.authorID == authorID }) {
                                            self.index.authors.append(AuthorMetadata(authorID: authorID, authorName: "Recovered Author", secUserID: nil))
                                        }
                                    } catch {}
                                }
                            }
                        }
                    }
                }
            }
            
            self.saveIndex()
            try fileManager.removeItem(at: dbURL)
            print("Successfully migrated from SQLite to Encrypted JSON")
        } catch {
            print("Migration failed: \(error)")
        }
    }
}

extension VaultJSONService {
    public static func wipeAllData() {
        let fileManager = FileManager.default
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        try? fileManager.removeItem(at: vaultURL)
        EncryptionManager.shared.deleteKey()
    }
}

extension VaultJSONService {
    public func getURL(for relativePath: String) -> URL {
        let vaultURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("ChronoKitVault")
        return vaultURL.appendingPathComponent(relativePath)
    }
}
