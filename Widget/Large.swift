import Intents
import SwiftUI
import WidgetKit

struct LargePhotoProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> LargePhotoEntry {
        LargePhotoEntry(
            date: Date(),
            data1: nil,
            data2: nil,
            data3: nil,
            data4: nil,
            configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (LargePhotoEntry) -> ()) {
        let entry = LargePhotoEntry(
            date: Date(),
            data1: nil,
            data2: nil,
            data3: nil,
            data4: nil,
            configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [LargePhotoEntry] = []
        let intents = SharedDataStoreManager.shared.getWidgetIntents()
        var usePhotos: [SharedPhoto] = []

        let MAX_PHOTO_NUM = 4

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
        for minOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minOffset * configuration.interval, to: currentDate)!
            let entry = LargePhotoEntry(
                date: entryDate,
                data1: usePhotos[0],
                data2: usePhotos[1],
                data3: usePhotos[2],
                data4: usePhotos[3],
                configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct LargePhotoEntry: TimelineEntry {
    let date: Date
    let data1: SharedPhoto?
    let data2: SharedPhoto?
    let data3: SharedPhoto?
    let data4: SharedPhoto?
    let configuration: ConfigurationIntent
}

struct LargePhotosEntryView: View {
    var entry: LargePhotoProvider.Entry

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .center) {
                    HStack {
                        if let data = entry.data1?.imageData {
                            Image(uiImage: UIImage(data: data)!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width / 2, height: geo.size.width / 2, alignment: .center)
                                .clipped()
                        }
                        if let data = entry.data2?.imageData {
                            Image(uiImage: UIImage(data: data)!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width / 2, height: geo.size.width / 2, alignment: .center)
                                .clipped()
                        }
                    }
                    .frame(width: geo.size.width, alignment: .center)
                    .padding(.top, 4)

                    HStack {
                        if let data = entry.data3?.imageData {
                            Image(uiImage: UIImage(data: data)!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width / 2, height: geo.size.width / 2, alignment: .center)
                                .clipped()
                        }
                        if let data = entry.data4?.imageData {
                            Image(uiImage: UIImage(data: data)!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width / 2, height: geo.size.width / 2, alignment: .center)
                                .clipped()
                        }
                    }
                    .frame(width: geo.size.width, alignment: .center)
                }
            }
        }
    }
}

struct LargePhotos: Widget {
    let kind: String = "LargePhotos"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: LargePhotoProvider()) { entry in
            LargePhotosEntryView(entry: entry)
        }
        .configurationDisplayName("ラージ")
        .description("写真4枚で構成するWidget")
        .supportedFamilies([.systemLarge])
    }
}
