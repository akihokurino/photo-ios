import ComposableArchitecture
import SwiftUI
import UIKit

enum SettingTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { state, action, _ in
            switch action {
            case .onAppear:
                state.savedAsset = SharedDataStoreManager.shared.loadAsset()
                return .none
            }
        }
    )
}

extension SettingTCA {
    enum Action: Equatable {
        case onAppear
    }

    struct State: Equatable {
        var savedAsset: [SharedAsset] = []
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct SettingView: View {
    let store: Store<SettingTCA.State, SettingTCA.Action>

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
                    ForEach(viewStore.savedAsset, id: \.self) { asset in
                        SharedAssetRow(asset: asset)
                            .frame(maxWidth: SettingView.thumbnailSize)
                            .frame(height: SettingView.thumbnailSize)
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct SharedAssetRow: View {
    let asset: SharedAsset

    private let thumbnailSize = CGSize(width: SettingView.thumbnailSize, height: SettingView.thumbnailSize)

    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: asset.imageData!)!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: thumbnailSize.width)
                .frame(height: thumbnailSize.height)
                .clipped()
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(store: .init(
            initialState: SettingTCA.State(),
            reducer: .empty,
            environment: SettingTCA.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
