import Foundation
import CryptoKit
import Security

@objc(ChronoKitEncryptionManager)
public class EncryptionManager: NSObject {
    
    public static let shared = EncryptionManager()
    
    private let keyTag = "com.chronokit.encryption.key".data(using: .utf8)!
    
    private override init() {
        super.init()
    }
    
    private var symmetricKey: SymmetricKey {
        get throws {
            if let key = retrieveKeyFromKeychain() {
                return key
            } else {
                let newKey = SymmetricKey(size: .bits256)
                try storeKeyInKeychain(key: newKey)
                return newKey
            }
        }
    }
    
    public func encrypt(data: Data) throws -> Data {
        let key = try self.symmetricKey
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }
    
    public func decrypt(data: Data) throws -> Data {
        let key = try self.symmetricKey
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }
    
    private func storeKeyInKeychain(key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data(Array($0)) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Remove existing item before saving to avoid duplicate error
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainStoreFailed(status)
        }
    }
    
    private func retrieveKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        }
        return nil
    }
    
    public enum EncryptionError: Error {
        case encryptionFailed
        case keychainStoreFailed(OSStatus)
    }
}
