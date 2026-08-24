import SwiftUI
import UIKit
import os.log


// Create the SwiftUI view
public struct SettingsView: SwiftUI.View {
    @AppStorage("download_button") private var downloadButton: Bool = false
    @AppStorage("ad_block_enabled") private var adBlockEnabled: Bool = false
    @AppStorage("high_quality") private var highQuality: Bool = false
    @AppStorage("ssl_bypass_enabled") private var sslBypassEnabled: Bool = false
    @AppStorage("debug_download_all_urls") private var debugDownloadAllUrls: Bool = false
    @AppStorage("log_all_headers") private var logAllHeaders: Bool = false
    @AppStorage("anon_profile_view_enabled") private var anonProfileViewEnabled: Bool = false
    @AppStorage("hide_story_views_enabled") private var hideStoryViewsEnabled: Bool = false
    
    @State private var showRestartAlert = false
    @State private var showClearDataAlert = false
    
    public var body: some SwiftUI.View {
        List {
            Section(header: Text("Status (App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"))")) {
                HStack {
                    Label("Supported App Version", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    statusIcon(BypassStatusManager.shared.getAppVersionStatus())
                }
                HStack {
                    Label("SSL Bypass", systemImage: "lock.shield.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    statusIcon(BypassStatusManager.shared.getSSLBypassStatus())
                }
            }
            
            Section(header: Text("Feed")) {
                Toggle(isOn: $downloadButton) {
                    Label("Download Button", systemImage: "arrow.down.circle.fill")
                }
                .tint(.blue)
                
                Toggle(isOn: $adBlockEnabled) {
                    Label("Block Ads", systemImage: "hand.raised.slash.fill")
                }
                .tint(.red)
            }
            
            Section(header: Text("Downloads")) {
                Toggle(isOn: $highQuality) {
                    Label("High Quality", systemImage: "4k.tv.fill")
                }
                .tint(.purple)
                
                Button(action: {
                    openVault()
                }) {
                    HStack {
                        Label("Media Vault", systemImage: "folder.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section(header: Text("Privacy")) {
                Toggle(isOn: $anonProfileViewEnabled) {
                    Label("Anonymous Profile Viewing", systemImage: "eye.slash.fill")
                }
                .tint(.blue)
                
                Toggle(isOn: $hideStoryViewsEnabled) {
                    Label("Hide My Story Views", systemImage: "play.slash.fill")
                }
                .tint(.blue)
            }
            
            Section(header: Text("Bypass")) {
                Toggle(isOn: $sslBypassEnabled) {
                    Label("Enable SSL Pinning", systemImage: "network.badge.shield.half.filled")
                }
                .tint(.green)
                .onChange(of: sslBypassEnabled) { _ in
                    showRestartAlert = true
                }
            }
            
            
            Section(header: Text("Privacy")) {
                Toggle(isOn: $anonProfileViewEnabled) {
                    Label("Anonymous Profile Viewing", systemImage: "eye.slash.fill")
                }
                .tint(.blue)
            }
            
            #if DEBUG
            Section(header: Text("Developer")) {
                Toggle(isOn: $debugDownloadAllUrls) {
                    Label("Debug Download All URLs", systemImage: "ladybug.fill")
                }
                
                Toggle(isOn: $logAllHeaders) {
                    Label("Log All Headers", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                
                Button(action: {
                    viewDebugLog()
                }) {
                    HStack {
                        Label("View Debug Log", systemImage: "doc.text.magnifyingglass")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
            }
            #endif
            
            Section(header: Text("About")) {
                Button(action: {
                    openURL("https://github.com/kunihir0/ChronoKit")
                }) {
                    HStack {
                        Label("Project Repo", systemImage: "chevron.left.forwardslash.chevron.right")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
                
                HStack {
                    Label("License", systemImage: "doc.plaintext.fill")
                    Spacer()
                    Text("Apache 2.0")
                        .foregroundColor(.secondary)
                }
                
                Menu {
                    Button("DouX") { openURL("https://github.com/kunihir0/DouX") }
                    Button("tiktokusregion") { openURL("https://github.com/iGerman00/tiktokusregion.git") }
                    Button("tiktok-god") { openURL("https://github.com/haoict/tiktok-god.git") }
                    Button("TikTok-Tweaks") { openURL("https://github.com/tuxi/TikTok-Tweaks.git") }
                } label: {
                    HStack {
                        Label("Credits", systemImage: "person.3.fill")
                        Spacer()
                        Text("View Credits")
                            .foregroundColor(.blue)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section(header: Text("Data Management")) {
                Button(role: .destructive, action: {
                    showClearDataAlert = true
                }) {
                    HStack {
                        Label("Clear Vault Data", systemImage: "trash.fill")
                    }
                }
                .alert(isPresented: $showClearDataAlert) {
                    Alert(
                        title: Text("Clear All Data?"),
                        message: Text("This will permanently delete all downloaded videos, photos, the encrypted database, and the encryption keys. This action cannot be undone. TikTok will restart immediately."),
                        primaryButton: .destructive(Text("Delete Everything")) {
                            VaultJSONService.wipeAllData()
                            exit(0)
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("ChronoKit Settings")
        .alert(isPresented: $showRestartAlert) {
            Alert(
                title: Text("Restart Required"),
                message: Text("Please restart the app for the changes to take effect."),
                primaryButton: .destructive(Text("Restart Now")) {
                    UserDefaults.standard.synchronize()
                    exit(0)
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
    }
    
    @ViewBuilder
    private func statusIcon(_ statusRaw: Int) -> some SwiftUI.View {
        let status = StatusIndicatorView.Status(rawValue: statusRaw) ?? .pending
        switch status {
        case .active:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .inactive:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        case .pending:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
        @unknown default:
            Image(systemName: "questionmark.circle.fill").foregroundColor(.gray)
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func pushViewController(_ vc: UIViewController) {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            if let nav = topController as? UINavigationController {
                nav.pushViewController(vc, animated: true)
            } else if let nav = topController.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                topController.present(vc, animated: true)
            }
        }
    }
    
    private func openVault() {
        let vaultVC = VaultCreatorsViewController()
        pushViewController(vaultVC)
    }
    
    private func viewDebugLog() {
        #if DEBUG
        let logContent = FileLogger.shared.readLog()
        let logVC = UIViewController()
        let textView = UITextView(frame: UIScreen.main.bounds)
        textView.text = logContent
        textView.isEditable = false
        logVC.view.addSubview(textView)
        logVC.title = "Debug Log"
        pushViewController(logVC)
        #endif
    }
}

// UIKit Wrapper for Theos/Logos to present
@objc(ChronoKitSettingsViewController)
public class SettingsViewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ChronoKit Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(closeTapped))
        
        let hostingController = UIHostingController(rootView: SettingsView())
        
        self.addChild(hostingController)
        hostingController.view.frame = self.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
