import ComposableArchitecture
import SwiftUI
import UIKit
import WidgetKit

enum SettingTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { state, action, _ in
            switch action {
            case .onAppear:
                state.selectedPhotos = SharedDataStoreManager.shared.loadAsset()
                return .none
            case .refresh:
                state.isRefreshing = true
                state.selectedPhotos = SharedDataStoreManager.shared.loadAsset()
                state.isRefreshing = false
                return .none
            case .delete(let photo):
                SharedDataStoreManager.shared.deleteAsset(asset: photo)
                state.isPresentedAlert = true
                state.alertText = "削除しました"
                state.selectedPhotos = SharedDataStoreManager.shared.loadAsset()
                
                WidgetCenter.shared.reloadAllTimelines()
                
                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            }
        }
    )
}

extension SettingTCA {
    enum Action: Equatable {
        case onAppear
        case refresh
        case delete(SharedPhoto)
        case isPresentedAlert(Bool)
    }

    struct State: Equatable {
        var selectedPhotos: [SharedPhoto] = []
        var isRefreshing = false
        var isPresentedAlert = false
        var alertText = ""
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
    ]

    @State private var isShowActionSheet = false
    @State private var selectedPhoto: SharedPhoto? = nil
    static let thumbnailSize = UIScreen.main.bounds.size.width / 2

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                RefreshControl(isRefreshing: Binding(
                    get: { viewStore.isRefreshing },
                    set: { _ in }
                ), coordinateSpaceName: "RefreshControl", onRefresh: {
                    viewStore.send(.refresh)
                })

                Text("ホームに表示する画像\n（ランダムに最大4つ表示されます）")
                    .foregroundColor(Color("Text"))
                    .font(Font.system(size: 15.0))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()

                LazyVGrid(columns: gridItemLayout, alignment: HorizontalAlignment.leading, spacing: 2) {
                    ForEach(viewStore.selectedPhotos, id: \.self) { photo in
                        Button(action: {
                            selectedPhoto = photo
                            isShowActionSheet = true
                        }) {
                            SharedPhotoRow(photo: photo)
                                .frame(maxWidth: SettingView.thumbnailSize)
                                .frame(height: SettingView.thumbnailSize)
                        }
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            .actionSheet(isPresented: $isShowActionSheet) {
                ActionSheet(title: Text("選択してください"), buttons:
                    [
                        .destructive(Text("削除")) {
                            guard let photo = selectedPhoto else {
                                return
                            }
                            viewStore.send(.delete(photo))
                        },
                        .cancel(Text("キャンセル")),
                    ])
            }
            .alert(isPresented: viewStore.binding(
                get: \.isPresentedAlert,
                send: SettingTCA.Action.isPresentedAlert
            )) {
                Alert(title: Text(viewStore.alertText))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct SharedPhotoRow: View {
    let photo: SharedPhoto

    private let thumbnailSize = CGSize(width: SettingView.thumbnailSize, height: SettingView.thumbnailSize)

    var body: some View {
        HStack {
            if let data = photo.imageData {
                Image(uiImage: UIImage(data: data)!)
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
