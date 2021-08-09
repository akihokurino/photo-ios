import ComposableArchitecture
import SwiftUI

enum RootTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        AssetListTCA.reducer.optional().pullback(
            state: \RootTCA.State.photoList,
            action: /RootTCA.Action.photoList,
            environment: { _environment in
                AssetListTCA.Environment(mainQueue: _environment.mainQueue, backgroundQueue: _environment.backgroundQueue)
            }
        ),
        SettingTCA.reducer.optional().pullback(
            state: \RootTCA.State.setting,
            action: /RootTCA.Action.setting,
            environment: { _environment in
                SettingTCA.Environment(mainQueue: _environment.mainQueue, backgroundQueue: _environment.backgroundQueue)
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

extension RootTCA {
    enum Action: Equatable {
        case onAppear
        case photoList(AssetListTCA.Action)
        case setting(SettingTCA.Action)
    }

    struct State: Equatable {
        var photoList: AssetListTCA.State? = AssetListTCA.State()
        var setting: SettingTCA.State? = SettingTCA.State()
    }

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct RootView: View {
    let store: Store<RootTCA.State, RootTCA.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            TabView {
                NavigationView {
                    IfLetStore(
                        store.scope(
                            state: { $0.photoList },
                            action: RootTCA.Action.photoList
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
                            action: RootTCA.Action.setting
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
            initialState: RootTCA.State(),
            reducer: .empty,
            environment: RootTCA.Environment(
                mainQueue: .main,
                backgroundQueue: .init(DispatchQueue.global(qos: .background))
            )
        ))
    }
}
