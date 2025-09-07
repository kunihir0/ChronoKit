
import Foundation

public class MediaVaultService {

    public static let shared = MediaVaultService()

    private let vaultURL: URL
    private let metadataURL: URL

    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultURL = documentsDirectory.appendingPathComponent("ChronoKitVault")
        self.metadataURL = self.vaultURL.appendingPathComponent("metadata.json")
        self.createVaultDirectoryIfNeeded()
    }

    private func createVaultDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: self.vaultURL.path) {
            do {
                try FileManager.default.createDirectory(at: self.vaultURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("ChronoKit Error: Could not create vault directory: \(error)")
            }
        }
    }

    public func saveMetadata(_ metadata: MediaMetadata) {
        var allMetadata = self.loadMetadata()
        allMetadata.append(metadata)
        do {
            let data = try JSONEncoder().encode(allMetadata)
            try data.write(to: self.metadataURL)
        } catch {
            NSLog("ChronoKit Error: Could not save metadata: \(error)")
        }
    }

    public func loadMetadata() -> [MediaMetadata] {
        if FileManager.default.fileExists(atPath: self.metadataURL.path) {
            do {
                let data = try Data(contentsOf: self.metadataURL)
                let metadata = try JSONDecoder().decode([MediaMetadata].self, from: data)
                return metadata
            } catch {
                NSLog("ChronoKit Error: Could not load metadata: \(error)")
            }
        }
        return []
    }
}
