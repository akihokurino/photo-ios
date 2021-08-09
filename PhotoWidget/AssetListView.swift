import Combine
import ComposableArchitecture
import SwiftUI

enum AssetListTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { state, action, _ in
            switch action {
            case .onAppear:
                return PhotosManager.requestAuthorization()
                    .eraseToEffect()
                    .map(AssetListTCA.Action.authorized)
            case .refresh:
                state.isRefreshing = true
                return PhotosManager.fetchAssets()
                    .eraseToEffect()
                    .map(AssetListTCA.Action.assets)
            case .authorized(.authorized):
                return PhotosManager.fetchAssets()
                    .eraseToEffect()
                    .map(AssetListTCA.Action.assets)
            case .authorized(let status):
                return .none
            case .assets(let assets):
                state.isRefreshing = false
                state.assets = assets
                return .none
            case .save(let asset):
                return PhotosManager.requestFullImage(asset: asset, deliveryMode: .highQualityFormat)
                    .flatMap { _ in
                        Future<Asset, Never> { promise in
                            let sharedAsset = SharedPhoto(photosId: asset.id, imageData: asset.image?.pngData())
                            SharedDataStoreManager.shared.saveAsset(asset: sharedAsset)
                            promise(.success(asset))
                        }
                    }
                    .eraseToEffect()
                    .map(AssetListTCA.Action.saved)
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

extension AssetListTCA {
    enum Action: Equatable {
        case onAppear
        case refresh
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
        var isRefreshing = false
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct AssetListView: View {
    let store: Store<AssetListTCA.State, AssetListTCA.Action>

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
                RefreshControl(isRefreshing: Binding(
                    get: { viewStore.isRefreshing },
                    set: { _ in }
                ), coordinateSpaceName: "RefreshControl", onRefresh: {
                    viewStore.send(.refresh)
                })

                LazyVGrid(columns: gridItemLayout, alignment: HorizontalAlignment.leading, spacing: 2) {
                    ForEach(viewStore.assets, id: \.self) { asset in
                        Button(action: {
                            selectedAsset = asset
                            isShowActionSheet = true
                        }) {
                            AssetRow(asset: asset)
                                .frame(maxWidth: AssetListView.thumbnailSize)
                                .frame(height: AssetListView.thumbnailSize)
                        }
                    }
                }
            }
            .coordinateSpace(name: "RefreshControl")
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
                send: AssetListTCA.Action.isPresentedAlert
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

    private let thumbnailSize = CGSize(width: AssetListView.thumbnailSize, height: AssetListView.thumbnailSize)

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
                    .gray
                    .frame(width: thumbnailSize.width)
                    .frame(height: thumbnailSize.height)
            }
        }
        .onAppear {
            asset.request(with: thumbnailSize)
        }
    }
}

struct AssetListView_Previews: PreviewProvider {
    static var previews: some View {
        AssetListView(store: .init(
            initialState: AssetListTCA.State(),
            reducer: .empty,
            environment: AssetListTCA.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
