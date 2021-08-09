import Foundation

let MAX_PHOTO_NUM = 60

struct SharedPhoto: Equatable, Codable, Hashable {
    var id: String
    var localId: String
    var imageData: Data?
    var createdAt: Date

    init(photosId: String, imageData: Data?) {
        self.id = UUID().uuidString
        self.localId = photosId
        self.imageData = imageData
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.localId = try values.decodeIfPresent(String.self, forKey: .localId) ?? ""
        self.imageData = try values.decodeIfPresent(Data.self, forKey: .imageData)
        self.createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct SharedPhotoRealmData: RealmStoreCodable {
    var key: String
    var storeType: RealmStoreType
    var value: SharedPhoto

    init(value: SharedPhoto) {
        self.key = value.id
        self.storeType = RealmStoreType.photo
        self.value = value
    }
}
