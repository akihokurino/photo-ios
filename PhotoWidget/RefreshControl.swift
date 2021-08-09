import SwiftUI

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    private let pullDownHeight: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .named(coordinateSpaceName)).midY > pullDownHeight {
                Spacer()
                    .onAppear() {
                        onRefresh()
                    }
            }
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView().padding()
                } else {
                    Text("⬇︎")
                        .font(.system(size: 28))
                }
                Spacer()
            }
        }.padding(.top, isRefreshing ? 0.0 : -50.0)
    }
}
