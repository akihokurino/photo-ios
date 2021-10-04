import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        SinglePhotos()
        WidePhotos()
        LargePhotos()
    }
}
