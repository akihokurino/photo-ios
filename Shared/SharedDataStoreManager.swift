import Combine
import Foundation
import Realm
import RealmSwift

private enum UserDefaultsKey {
    static let suiteName = "group.com.photo-widget"
    static let widgetIntents = "widgetIntents"
}

struct SharedDataStoreManager {
    let store = UserDefaults.standard

    static let shared = SharedDataStoreManager()
    private init() {}

    func saveAsset(asset: SharedPhoto) {
        saveWidgetIntent(.init(id: asset.id, createdAt: asset.createdAt))
        let data = SharedPhotoRealmData(value: asset)
        RealmClient.shared.save(value: data)
    }

    func loadAsset() -> [SharedPhoto] {
        let data: [SharedPhotoRealmData] = RealmClient.shared.load(storeType: .photo)
        return data.map { $0.value }
    }

    func deleteAsset(asset: SharedPhoto) {
        deleteWidgetIntent(id: asset.id)
        let data = SharedPhotoRealmData(value: asset)
        RealmClient.shared.delete(value: data)
    }

    private func getWidgetIntents() -> [WidgetIntent] {
        guard let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName) else { return [] }
        if let data = userDefaults.object(forKey: UserDefaultsKey.widgetIntents) as? Data,
           let intents = try? JSONDecoder().decode([WidgetIntent].self, from: data)
        {
            return intents
        } else {
            return []
        }
    }

    private func saveWidgetIntent(_ intent: WidgetIntent) {
        guard let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName) else { return }
        let current: [WidgetIntent] = getWidgetIntents()
        let value = try? JSONEncoder().encode(current + [intent])
        userDefaults.set(value, forKey: UserDefaultsKey.widgetIntents)
    }

    private func deleteWidgetIntent(id: String) {
        guard let userDefaults = UserDefaults(suiteName: UserDefaultsKey.suiteName) else { return }
        var current: [WidgetIntent] = getWidgetIntents()
        if current.isEmpty {
            return
        }
        current.removeAll(where: { $0.id == id })
        let value = try? JSONEncoder().encode(current)
        userDefaults.set(value, forKey: UserDefaultsKey.widgetIntents)
    }
}

enum RealmStoreType: String, Codable {
    case photo
}

protocol RealmStoreCodable: Codable {
    var key: String { get }
    var storeType: RealmStoreType { get }
}

final class RealmClient {
    static let shared = RealmClient(fileName: "db.realm")

    private let lock = NSRecursiveLock()
    private let realm: Realm?

    init(fileName: String) {
        let groupID: String = "group.com.photo-widget"
        var config = Realm.Configuration(schemaVersion: 0)
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
        config.fileURL = url.appendingPathComponent("db.realm")

        do {
            realm = try Realm(configuration: config)
            print("Realm data location...")
            print(Realm.Configuration.defaultConfiguration.fileURL!)
        } catch {
            realm = nil
        }
    }

    func hasKey(key: String) -> Bool {
        guard let realm = realm else { return false }
        return realm.object(ofType: RealmModel.self, forPrimaryKey: key) != nil
    }

    func load<T: RealmStoreCodable>(storeType: RealmStoreType) -> [T] {
        guard let realm = self.realm else {
            return []
        }

        let datas = realm.objects(RealmModel.self)
        return datas
            .filter { data -> Bool in
                data.storeType == storeType.rawValue
            }
            .compactMap { kvs -> T? in
                if let data = kvs.value {
                    return try? JSONDecoder().decode(T.self, from: data)
                } else {
                    return nil
                }
            }
    }

    func get<T: RealmStoreCodable>(key: String) -> T? {
        guard
            let realm = realm,
            let cache = realm.object(ofType: RealmModel.self, forPrimaryKey: key),
            let cacheValue = cache.value
        else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: cacheValue)
    }

    func save<T: RealmStoreCodable>(value: T) {
        let key = value.key
        let storeType = value.storeType
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? realm?.write {
            let kvs = RealmModel()
            kvs.key = key
            kvs.value = data
            kvs.storeType = storeType.rawValue
            self.realm?.add(kvs, update: .all)
        }
    }

    func delete<T: RealmStoreCodable>(value: T) {
        guard let object = realm?.object(ofType: RealmModel.self, forPrimaryKey: value.key) else { return }
        try? realm?.write {
            self.realm?.delete(object)
        }
    }
}

final class RealmModel: Object {
    @objc dynamic var key: String?
    @objc dynamic var value: Data?
    @objc dynamic var storeType: String?
    @objc dynamic var createdAt = Date()

    override static func primaryKey() -> String? {
        return "key"
    }
}
