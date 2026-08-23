import Foundation

@objc(ChronoKitFileLogger)
public class FileLogger: NSObject {
    @objc public static let shared = FileLogger()

    override private init() {
        super.init()
        // Securely delete any existing log file
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFileURL = docsURL.appendingPathComponent("ChronoKit_SuperDebug.log")
        try? fileManager.removeItem(at: logFileURL)
    }

    @objc(log:)
    public func log(_ message: String) {
        // Disabled for Zero-Trace architecture
    }

    func readLog() -> String {
        return "Log file is disabled for security."
    }

    func clearLog() {
        // Disabled
    }
}
