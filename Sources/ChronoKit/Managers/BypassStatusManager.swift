import Foundation

@objc(ChronoKitBypassStatusManager)
public class BypassStatusManager: NSObject {

    @objc public static let shared = BypassStatusManager()

    private override init() {}

    @objc public func getBypassStatus() -> Int {
        // In a real implementation, we would perform checks here to determine the
        // status of the jailbreak bypass. For now, we'll just return a pending status.
        return 0 // 0 for active, 1 for inactive, 2 for pending
    }

    @objc public func getSSLBypassStatus() -> Int {
        let isEnabled = UserDefaults.standard.bool(forKey: "ssl_bypass_enabled")
        return isEnabled ? 0 : 1 // 0 for active, 1 for inactive
    }

    @objc public func getAppVersionStatus() -> Int {
        guard let currentVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return 1 // Return inactive/unsupported if version can't be determined
        }

        let supportedVersionString = "46.6.0"

        // Using numeric comparison to correctly handle version strings
        if currentVersionString.compare(supportedVersionString, options: .numeric) != .orderedDescending {
            return 0 // active/supported (current <= supported)
        } else {
            return 1 // inactive/unsupported (current > supported)
        }
    }
}