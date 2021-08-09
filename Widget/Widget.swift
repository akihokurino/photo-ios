import Intents
import SwiftUI
import WidgetKit

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: nil, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let photos = SharedDataStoreManager.shared.loadAsset()
//        var usePhotos: [SharedPhoto] = []
//
//        if photos.count < MAX_PHOTO_NUM {
//            loop: while true {
//                for photo in photos {
//                    usePhotos.append(photo)
//
//                    if usePhotos.count >= MAX_PHOTO_NUM {
//                        break loop
//                    }
//                }
//
//                if usePhotos.count >= MAX_PHOTO_NUM {
//                    break loop
//                }
//            }
//        } else {
//            usePhotos = photos[0 ..< MAX_PHOTO_NUM].map { $0 }
//        }
//
//        let currentDate = Date()
//        for minOffset in 0 ..< 60 {
//            let entryDate = Calendar.current.date(byAdding: .minute, value: minOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, data: usePhotos[minOffset], configuration: configuration)
//            entries.append(entry)
//        }

        let entry = SimpleEntry(date: Date(), data: photos.first, configuration: configuration)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: SharedPhoto?
    let configuration: ConfigurationIntent
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let data = entry.data?.imageData {
            Image(uiImage: UIImage(data: data)!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
    }
}

@main
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("写真アルバム")
        .description("")
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        HomeWidgetEntryView(entry: SimpleEntry(date: Date(), data: nil, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
