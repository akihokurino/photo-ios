import Combine
import ComposableArchitecture
import SwiftUI

enum PhotoListTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { state, action, _ in
            switch action {
            case .onAppear:
                return PhotosManager.requestAuthorization()
                    .eraseToEffect()
                    .map(PhotoListTCA.Action.authorized)
            case .authorized(.authorized):
                return PhotosManager.fetchAssets()
                    .eraseToEffect()
                    .map(PhotoListTCA.Action.assets)
            case .authorized(let status):
                return .none
            case .assets(let assets):
                state.assets = assets
                return .none
            case .save(let asset):
                return PhotosManager.requestFullImage(asset: asset, deliveryMode: .highQualityFormat)
                    .flatMap { image in
                        Future<Asset, Never> { promise in
                            let sharedAsset = SharedAsset(photosId: asset.id, imageData: asset.image?.pngData())
                            SharedDataStoreManager.shared.saveAsset(asset: sharedAsset)
                            promise(.success(asset))
                        }
                    }
                    .eraseToEffect()
                    .map(PhotoListTCA.Action.saved)
            case .saved(let asset):
                state.isPresentedAlert = true
                state.alertText = "写真を保存しました"
                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            }
        }
    )
}

extension PhotoListTCA {
    enum Action: Equatable {
        case onAppear
        case authorized(PhotoAuthorizationStatus)
        case assets([Asset])
        case save(Asset)
        case saved(Asset)
        case isPresentedAlert(Bool)
    }

    struct State: Equatable {
        var assets: [Asset] = []
        var isPresentedAlert = false
        var alertText = ""
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct PhotoListView: View {
    let store: Store<PhotoListTCA.State, PhotoListTCA.Action>

    private let gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    @State private var isShowActionSheet = false
    @State private var selectedAsset: Asset? = nil
    static let thumbnailSize = UIScreen.main.bounds.size.width / 4

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVGrid(columns: gridItemLayout, alignment: HorizontalAlignment.leading, spacing: 2) {
                    ForEach(viewStore.assets, id: \.self) { asset in
                        Button(action: {
                            selectedAsset = asset
                            isShowActionSheet = true
                        }) {
                            AssetRow(asset: asset)
                                .frame(maxWidth: PhotoListView.thumbnailSize)
                                .frame(height: PhotoListView.thumbnailSize)
                        }
                    }
                }
            }
            .navigationBarTitle("写真", displayMode: .inline)
            .actionSheet(isPresented: $isShowActionSheet) {
                ActionSheet(title: Text("選択してください"), buttons:
                    [
                        .default(Text("保存")) {
                            guard let asset = selectedAsset else {
                                return
                            }
                            viewStore.send(.save(asset))
                        },
                        .cancel(Text("キャンセル")),
                    ])
            }
            .alert(isPresented: viewStore.binding(
                get: \.isPresentedAlert,
                send: PhotoListTCA.Action.isPresentedAlert
            )) {
                Alert(title: Text(viewStore.alertText))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct AssetRow: View {
    @ObservedObject var asset: Asset

    private let thumbnailSize = CGSize(width: PhotoListView.thumbnailSize, height: PhotoListView.thumbnailSize)

    var body: some View {
        HStack {
            if let image = asset.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize.width)
                    .frame(height: thumbnailSize.height)
                    .clipped()

            } else {
                Color
                    .white
                    .frame(maxWidth: thumbnailSize.width)
                    .frame(height: thumbnailSize.height)
            }
        }
        .onAppear {
            asset.request(with: thumbnailSize)
        }
    }
}

struct PhotoListView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoListView(store: .init(
            initialState: PhotoListTCA.State(),
            reducer: .empty,
            environment: PhotoListTCA.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
