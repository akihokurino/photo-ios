import Foundation

struct SharedAsset: Equatable, Codable, Hashable {
    var id: String
    var photosId: String
    var imageData: Data?
    var createdAt: Date

    init(photosId: String, imageData: Data?) {
        self.id = UUID().uuidString
        self.photosId = photosId
        self.imageData = imageData
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.photosId = try values.decodeIfPresent(String.self, forKey: .photosId) ?? ""
        self.imageData = try values.decodeIfPresent(Data.self, forKey: .imageData)
        self.createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct SharedAssetStore: RealmStoreCodable {
    var key: String
    var storeType: RealmStoreType
    var value: SharedAsset

    init(value: SharedAsset) {
        self.key = value.id
        self.storeType = RealmStoreType.asset
        self.value = value
    }
}
