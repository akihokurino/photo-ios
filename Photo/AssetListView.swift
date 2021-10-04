import Combine
import ComposableArchitecture
import SwiftUI

enum AssetListVM {
    static let reducer = Reducer<State, Action, Environment>.combine(
        CropVM.reducer.optional().pullback(
            state: \AssetListVM.State.cropView,
            action: /AssetListVM.Action.cropView,
            environment: { _environment in
                CropVM.Environment(mainQueue: _environment.mainQueue, backgroundQueue: _environment.backgroundQueue)
            }
        ),
        Reducer { state, action, environment in
            switch action {
            case .onAppear:
                return PhotosManager.requestAuthorization()
                    .eraseToEffect()
                    .map(AssetListVM.Action.authorized)
            case .authorized(.authorized):
                return PhotosManager.fetchAssets()
                    .subscribe(on: environment.backgroundQueue)
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(AssetListVM.Action.assets)
            case .authorized(let status):
                return .none
            case .assets(let assets):
                state.assets = assets
                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            case .isPresentedCropView(let val):
                state.isPresentedCropView = val
                return .none
            case .showCropView(let asset):
                state.cropView = CropVM.State(asset: asset)
                state.isPresentedCropView = true
                return .none
            case .cropView(let action):
                switch action {
                case .register:
                    state.isPresentedAlert = true
                    state.alertText = "写真を追加しました"
                    state.isPresentedCropView = false
                    state.cropView = nil
                    return .none
                case .back:
                    state.isPresentedCropView = false
                    state.cropView = nil
                    return .none
                }
            }
        }
    )
}

extension AssetListVM {
    enum Action: Equatable {
        case onAppear
        case authorized(PhotoAuthorizationStatus)
        case assets([Asset])
        case isPresentedAlert(Bool)
        case isPresentedCropView(Bool)
        case showCropView(Asset)

        case cropView(CropVM.Action)
    }

    struct State: Equatable {
        var assets: [Asset] = []
        var isPresentedAlert = false
        var alertText = ""
        var isPresentedCropView = false

        var cropView: CropVM.State? = nil
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

    static let thumbnailSize = UIScreen.main.bounds.size.width / 4

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVGrid(columns: gridItemLayout, alignment: HorizontalAlignment.leading, spacing: 2) {
                    ForEach(viewStore.assets, id: \.self) { asset in
                        Button(action: {
                            viewStore.send(.showCropView(asset))
                        }) {
                            AssetRow(asset: asset)
                                .frame(maxWidth: AssetListView.thumbnailSize)
                                .frame(height: AssetListView.thumbnailSize)
                        }
                    }
                }
            }
            .navigationBarTitle("写真", displayMode: .inline)
            .alert(isPresented: viewStore.binding(
                get: \.isPresentedAlert,
                send: AssetListVM.Action.isPresentedAlert
            )) {
                Alert(title: Text(viewStore.alertText))
            }
            .fullScreenCover(isPresented: viewStore.binding(
                get: \.isPresentedCropView,
                send: AssetListVM.Action.isPresentedCropView
            )) {
                IfLetStore(
                    store.scope(
                        state: { $0.cropView },
                        action: AssetListVM.Action.cropView
                    ),
                    then: CropView.init(store:)
                )
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

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: AssetListView.thumbnailSize)
                    .frame(height: AssetListView.thumbnailSize)
                    .clipped()

            } else {
                Color
                    .gray
                    .frame(width: AssetListView.thumbnailSize)
                    .frame(height: AssetListView.thumbnailSize)
            }
        }
        .onAppear {
            asset.request(with: CGSize(width: AssetListView.thumbnailSize * 3, height: AssetListView.thumbnailSize * 3)) { image in
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
