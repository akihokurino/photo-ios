import ComposableArchitecture
import SwiftUI

enum SettingTCA {
    static let reducer = Reducer<State, Action, Environment>.combine(
        Reducer { _, action, _ in
            switch action {
            case .onAppear:
                return .none
            }
        }
    )
}

extension SettingTCA {
    enum Action: Equatable {
        case onAppear
    }

    struct State: Equatable {}

    struct Environment {
        let mainQueue: AnySchedulerOf<DispatchQueue>
        let backgroundQueue: AnySchedulerOf<DispatchQueue>
    }
}

struct SettingView: View {
    let store: Store<SettingTCA.State, SettingTCA.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {}
                .navigationBarTitle("設定", displayMode: .inline)
                .onAppear {
                    viewStore.send(.onAppear)
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
