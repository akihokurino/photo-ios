import Intents
import SwiftUI
import WidgetKit
import UIKit

struct SinglePhotoProvider: IntentTimelineProvider {
    typealias Intent = ConfigurationIntent
    typealias Entry = SinglePhotoEntry

    func placeholder(in context: Context) -> SinglePhotoEntry {
        SinglePhotoEntry(
            date: Date(),
            data: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SinglePhotoEntry) -> ()) {
        let entry = SinglePhotoEntry(
            date: Date(),
            data: SharedPhoto(photosId: "", imageData: UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)),
            configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SinglePhotoEntry] = []
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
        for minOffset in 0 ..< MAX_PHOTO_NUM {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minOffset * configuration.interval, to: currentDate)!
            let entry = SinglePhotoEntry(date: entryDate, data: usePhotos[minOffset], configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SinglePhotoEntry: TimelineEntry {
    let date: Date
    let data: SharedPhoto?
    let configuration: ConfigurationIntent
}

struct SinglePhotosEntryView: View {
    var entry: SinglePhotoProvider.Entry

    var body: some View {
        if let data = entry.data?.imageData {
            ZStack {
                Image(uiImage: UIImage(data: data)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            }
        }
    }
}

struct SinglePhotos: Widget {
    let kind: String = "SinglePhotos"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: SinglePhotoProvider()) { entry in
            SinglePhotosEntryView(entry: entry)
        }
        .configurationDisplayName("シングル")
        .description("写真1枚で構成するWidget")
        .supportedFamilies([.systemSmall])
    }
}
