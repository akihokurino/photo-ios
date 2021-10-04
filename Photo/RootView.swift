import ComposableArchitecture
import SwiftUI

enum RootVM {
    static let reducer = Reducer<State, Action, Environment>.combine(
        AssetListVM.reducer.optional().pullback(
            state: \RootVM.State.photoList,
            action: /RootVM.Action.photoList,
            environment: { _environment in
                AssetListVM.Environment(mainQueue: _environment.mainQueue, backgroundQueue: _environment.backgroundQueue)
            }
        ),
        SettingVM.reducer.optional().pullback(
            state: \RootVM.State.setting,
            action: /RootVM.Action.setting,
            environment: { _environment in
                SettingVM.Environment(mainQueue: _environment.mainQueue, backgroundQueue: _environment.backgroundQueue)
            }
        ),
        Reducer { _, action, _ in
            switch action {
            case .onAppear:
                return .none
            case .photoList(let action):
                return .none
            case .setting(let action):
                return .none
            }
        }
    )
}

extension RootVM {
    enum Action: Equatable {
        case onAppear
        case photoList(AssetListVM.Action)
        case setting(SettingVM.Action)
    }

    struct State: Equatable {
        var photoList: AssetListVM.State? = AssetListVM.State()
        var setting: SettingVM.State? = SettingVM.State()
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct RootView: View {
    let store: Store<RootVM.State, RootVM.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            TabView {
                NavigationView {
                    IfLetStore(
                        store.scope(
                            state: { $0.photoList },
                            action: RootVM.Action.photoList
                        ),
                        then: AssetListView.init(store:)
                    )
                }
                .tabItem {
                    VStack {
                        Image(systemName: "photo")
                        Text("一覧")
                    }
                }.tag(1)

                NavigationView {
                    IfLetStore(
                        store.scope(
                            state: { $0.setting },
                            action: RootVM.Action.setting
                        ),
                        then: SettingView.init(store:)
                    )
                }
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape")
                        Text("設定")
                    }
                }.tag(2)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(store: .init(
            initialState: RootVM.State(),
            reducer: .empty,
            environment: RootVM.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
