import SwiftUI
import UIKit

public struct VaultCreatorsView: SwiftUI.View {
    @State private var creators: [(authorID: String, authorName: String)] = []
    @State private var allItemsCount: Int = 0
    @State private var creatorCounts: [String: Int] = [:]
    
    var pushBrowser: ((String?, String) -> Void)?
    
    public var body: some SwiftUI.View {
        List {
            Section {
                Button(action: {
                    pushBrowser?(nil, "All Items")
                }) {
                    HStack {
                        Label("All Items", systemImage: "photo.on.rectangle.angled")
                        Spacer()
                        Text("\(allItemsCount)")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section(header: Text("Creators")) {
                ForEach(creators, id: \.authorID) { creator in
                    Button(action: {
                        pushBrowser?(creator.authorID, creator.authorName)
                    }) {
                        HStack {
                            Label(creator.authorName, systemImage: "person.crop.circle.fill")
                            Spacer()
                            Text("\(creatorCounts[creator.authorID] ?? 0)")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Media Vault")
        .onAppear {
            fetchData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChronoKitVaultDidMigrate"))) { _ in
            fetchData()
        }
    }
    
    private func fetchData() {
        do {
            allItemsCount = try VaultDatabaseService.shared.getTotalMediaCount()
            creators = try VaultDatabaseService.shared.fetchCreators()
            
            for creator in creators {
                creatorCounts[creator.authorID] = (try? VaultDatabaseService.shared.getMediaCount(for: creator.authorID)) ?? 0
            }
        } catch {
            print("Error fetching creators: \(error)")
        }
    }
}

@objc(ChronoKitVaultCreatorsViewController)
public class VaultCreatorsViewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGroupedBackground
        

        var creatorsView = VaultCreatorsView()
        creatorsView.pushBrowser = { [weak self] creatorID, title in
            let browserVC = VaultBrowserViewController(creatorID: creatorID)
            browserVC.title = title
            self?.navigationController?.pushViewController(browserVC, animated: true)
        }
        
        let hostingController = UIHostingController(rootView: creatorsView)
        self.addChild(hostingController)
        hostingController.view.frame = self.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}
