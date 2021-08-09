import Intents
import SwiftUI
import WidgetKit

let MAX_PHOTO_NUM = 4

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
        let intents = SharedDataStoreManager.shared.getWidgetIntents()
        var usePhotos: [SharedPhoto] = []

        loop: while true {
            for intent in intents.shuffled() {
                let photo = SharedDataStoreManager.shared.getAsset(id: intent.id)!
                usePhotos.append(photo)

                if usePhotos.count >= MAX_PHOTO_NUM {
                    break loop
                }
            }

            if usePhotos.count >= MAX_PHOTO_NUM {
                break loop
            }
        }

        let currentDate = Date()
        for minOffset in 0 ..< MAX_PHOTO_NUM {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, data: usePhotos[minOffset], configuration: configuration)
            entries.append(entry)
        }

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
