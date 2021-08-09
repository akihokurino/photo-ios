import ComposableArchitecture
import SwiftUI

@main
struct PhotoWidgetApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    let store: Store<RootTCA.State, RootTCA.Action> = Store(
        initialState: RootTCA.State(),
        reducer: RootTCA.reducer,
        environment: RootTCA.Environment(
            mainQueue: .main,
            backgroundQueue: .init(DispatchQueue.global(qos: .background))
        )
    )

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
}
