import Foundation

@objc(ChronoKitFileLogger)
public class FileLogger: NSObject {
    @objc public static let shared = FileLogger()
    private let logFileURL: URL

    override private init() {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = docsURL.appendingPathComponent("ChronoKit_SuperDebug.log")
    }

    @objc(log:)
    public func log(_ message: String) {
        let formattedMessage = "\(Date()): \(message)\n\n"
        if let data = formattedMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }
    }

    func readLog() -> String {
        return (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "Log file is empty or could not be read."
    }

    func clearLog() {
        try? FileManager.default.removeItem(at: logFileURL)
    }
}
