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
            }
        }
    )
}

extension PhotoListTCA {
    enum Action: Equatable {
        case onAppear
        case authorized(PhotoAuthorizationStatus)
        case assets([Asset])
    }

    struct State: Equatable {
        var assets: [Asset] = []
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

    static let thumbnailSize = UIScreen.main.bounds.size.width / 4

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVGrid(columns: gridItemLayout, alignment: HorizontalAlignment.leading, spacing: 2) {
                    ForEach(viewStore.assets, id: \.self) { asset in
                        Button(action: {}) {
                            PhotoRow(asset: asset)
                                .frame(maxWidth: PhotoListView.thumbnailSize)
                                .frame(height: PhotoListView.thumbnailSize)
                        }
                    }
                }
            }
            .navigationBarTitle("写真", displayMode: .inline)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct PhotoRow: View {
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
