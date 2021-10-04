import Intents
import SwiftUI
import WidgetKit

struct WidePhotoProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> WidePhotoEntry {
        WidePhotoEntry(
            date: Date(),
            data1: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            data2: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WidePhotoEntry) -> ()) {
        let entry = WidePhotoEntry(
            date: Date(),
            data1: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            data2: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [WidePhotoEntry] = []
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

        let chunked = usePhotos.chunked(by: 2)

        let currentDate = Date()
        for minOffset in 0 ..< MAX_PHOTO_NUM / 2 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minOffset * configuration.interval, to: currentDate)!
            let entry = WidePhotoEntry(
                date: entryDate,
                data1: chunked[minOffset][0],
                data2: chunked[minOffset][1],
                configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WidePhotoEntry: TimelineEntry {
    let date: Date
    let data1: SharedPhoto?
    let data2: SharedPhoto?
    let configuration: ConfigurationIntent
}

struct WidePhotosEntryView: View {
    var entry: WidePhotoProvider.Entry

    var body: some View {
        GeometryReader { geo in
            ZStack {
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
            }
        }
    }
}

struct WidePhotos: Widget {
    let kind: String = "WidePhotos"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: WidePhotoProvider()) { entry in
            WidePhotosEntryView(entry: entry)
        }
        .configurationDisplayName("ワイド")
        .description("写真2枚で構成するWidget")
        .supportedFamilies([.systemMedium])
    }
}

