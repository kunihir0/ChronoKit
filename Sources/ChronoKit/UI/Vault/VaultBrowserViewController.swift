import SwiftUI
import UIKit

class ThumbnailLoader: ObservableObject {
    @Published var image: UIImage?
    
    func load(mediaItem: MediaMetadata) {
        ThumbnailService.shared.getThumbnail(for: mediaItem) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

struct VaultItemThumbnailView: SwiftUI.View {
    let mediaItem: MediaMetadata
    @StateObject private var loader = ThumbnailLoader()
    
    var body: some SwiftUI.View {
        ZStack {
            Color.gray.opacity(0.3)
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
            
            if mediaItem.mediaType == .video {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .shadow(radius: 2)
                        Spacer()
                    }
                }
            }
            
            if mediaItem.isFavorite {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(4)
                            .shadow(radius: 2)
                    }
                    Spacer()
                }
            }
        }
        .clipped()
        .onAppear {
            loader.load(mediaItem: mediaItem)
        }
    }
}

public struct VaultBrowserView: SwiftUI.View {
    let creatorID: String?
    
    @State private var media: [MediaMetadata] = []
    @State private var isFavoritesFilterActive = false
    
    enum SortMode {
        case downloadDate
        case creationDate
    }
    @State private var currentSortMode: SortMode = .downloadDate
    
    var presentViewer: (([MediaMetadata], Int) -> Void)?
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var itemsToDisplay: [MediaMetadata] {
        var items = isFavoritesFilterActive ? media.filter { $0.isFavorite } : media
        switch currentSortMode {
        case .downloadDate:
            items.sort { $0.downloadDate > $1.downloadDate }
        case .creationDate:
            items.sort { $0.creationDate > $1.creationDate }
        }
        return items
    }
    
    public var body: some SwiftUI.View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(itemsToDisplay.enumerated()), id: \.element.itemID) { index, item in
                    VaultItemThumbnailView(mediaItem: item)
                        .aspectRatio(1, contentMode: .fill)
                        .onTapGesture {
                            presentViewer?(itemsToDisplay, index)
                        }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    isFavoritesFilterActive.toggle()
                }) {
                    Image(systemName: isFavoritesFilterActive ? "heart.fill" : "heart")
                }
                
                Menu {
                    Button("Sort by Download Date") { currentSortMode = .downloadDate }
                    Button("Sort by Creation Date") { currentSortMode = .creationDate }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .onAppear {
            loadMedia()
        }
    }
    
    private func loadMedia() {
        do {
            self.media = try VaultDatabaseService.shared.loadMedia(for: self.creatorID)
        } catch {
            print("Error loading media: \(error)")
        }
    }
}

@objc(ChronoKitVaultBrowserViewController)
public class VaultBrowserViewController: UIViewController {
    private var creatorID: String?
    
    public init(creatorID: String?) {
        self.creatorID = creatorID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:)")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        var browserView = VaultBrowserView(creatorID: creatorID)
        browserView.presentViewer = { [weak self] items, index in
            let pageVC = MediaViewerPageViewController(mediaItems: items, initialIndex: index)
            pageVC.modalPresentationStyle = .fullScreen
            self?.present(pageVC, animated: true, completion: nil)
        }
        
        let hostingController = UIHostingController(rootView: browserView)
        self.addChild(hostingController)
        hostingController.view.frame = self.view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}
