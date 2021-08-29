import Combine
import ComposableArchitecture
import SwiftUI
import WidgetKit

enum AssetListVM {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { state, action, environment in
            switch action {
            case .onAppear:
                return PhotosManager.requestAuthorization()
                    .eraseToEffect()
                    .map(AssetListVM.Action.authorized)
            case .refresh:
                state.isRefreshing = true
                return PhotosManager.fetchAssets()
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(AssetListVM.Action.assets)
            case .authorized(.authorized):
                return PhotosManager.fetchAssets()
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(AssetListVM.Action.assets)
            case .authorized(let status):
                return .none
            case .assets(let assets):
                state.isRefreshing = false
                state.assets = assets
                return .none
            case .save(let asset):
                return PhotosManager.requestImage(asset: asset, targetSize: CGSize(width: 300, height: 300))
                    .flatMap { image in
                        Future<Asset, Never> { promise in
                            let sharedAsset = SharedPhoto(photosId: asset.id, imageData: image?.pngData())
                            SharedDataStoreManager.shared.saveAsset(asset: sharedAsset)
                            promise(.success(asset))
                        }
                    }
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(AssetListVM.Action.saved)
            case .saved(let asset):
                state.isPresentedAlert = true
                state.alertText = "写真を追加しました"

                WidgetCenter.shared.reloadAllTimelines()

                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            }
        }
    )
}

extension AssetListVM {
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
    let store: Store<AssetListVM.State, AssetListVM.Action>

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
                        .default(Text("ホームに表示する")) {
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
                send: AssetListVM.Action.isPresentedAlert
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
    @State var image: UIImage? = nil

    private let thumbnailSize = CGSize(width: AssetListView.thumbnailSize, height: AssetListView.thumbnailSize)

    var body: some View {
        HStack {
            if let image = image {
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
            asset.request(with: CGSize(width: AssetListView.thumbnailSize * 2, height: AssetListView.thumbnailSize * 2)) { image in
                self.image = image
            }
        }
    }
}

struct AssetListView_Previews: PreviewProvider {
    static var previews: some View {
        AssetListView(store: .init(
            initialState: AssetListVM.State(),
            reducer: .empty,
            environment: AssetListVM.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
